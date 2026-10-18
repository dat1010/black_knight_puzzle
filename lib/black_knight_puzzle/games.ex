defmodule BlackKnightPuzzle.Games do
  @moduledoc """
  The Games context.
  """
  import Ecto.Query, warn: false
  alias BlackKnightPuzzle.Repo
  alias BlackKnightPuzzle.Accounts.User
  alias BlackKnightPuzzle.Game.BlackKnight

  alias BlackKnightPuzzle.Games.Game
  alias BlackKnightPuzzle.Games.DailyPuzzle
  alias BlackKnightPuzzle.Games.DailyPuzzleScore
  alias BlackKnightPuzzle.Games.UserGame
  alias BlackKnightPuzzle.Games.UserGameMove
  alias BlackKnightPuzzle.Game.DailyPuzzleGenerator

  # database getters

  @classic_game_name "BlackKnightPuzzle"

  @doc """
  Gets the classic Black Knight Puzzle game row.
  """
  def get_classic_game! do
    from(g in Game, where: g.name == ^@classic_game_name, order_by: g.id, limit: 1)
    |> Repo.one!()
  end

  @doc """
  Lists a user's games, most recently played first.
  """
  def list_user_games(%User{id: user_id}) do
    from(g in UserGame,
      where: g.user_id == ^user_id,
      order_by: [desc: g.updated_at],
      preload: [:user_game_moves]
    )
    |> Repo.all()
  end

  @doc """
  Gets one of the user's games.

  Raises `Ecto.NoResultsError` (rendered as a 404) if the game doesn't exist or
  belongs to someone else.
  """
  def get_user_game!(%User{id: user_id}, user_game_id) do
    from(g in UserGame,
      where: g.id == ^user_game_id and g.user_id == ^user_id,
      preload: [:user_game_moves]
    )
    |> Repo.one!()
  end

  @doc """
  Starts a new classic game for the user.
  """
  def start_user_game(%User{id: user_id}) do
    create_user_game(%{
      user_id: user_id,
      game_id: get_classic_game!().id,
      current_state: BlackKnight.set_board()
    })
  end

  @doc """
  Saves a move on a user's game: records the move and the new board, and marks
  the game won when `won?` is true. Both writes happen in one transaction.
  """
  def record_user_game_move(%UserGame{} = user_game, move, new_state, won?) do
    Repo.transaction(fn ->
      with {:ok, _move} <- create_user_game_move(%{user_game_id: user_game.id, move: move}),
           {:ok, user_game} <-
             user_game
             |> UserGame.changeset(%{current_state: new_state, won: user_game.won or won?})
             |> Repo.update() do
        user_game
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  def get_daily_puzzle(date) do
    Repo.get_by(DailyPuzzle, puzzle_date: date)
  end

  def get_or_create_daily_puzzle(date \\ Date.utc_today()) do
    case get_daily_puzzle(date) do
      nil -> create_daily_puzzle_for_date(date)
      daily_puzzle -> daily_puzzle
    end
  end

  def create_daily_puzzle_for_date(date) do
    attrs = DailyPuzzleGenerator.generate(date, daily_puzzle_generator_opts())

    %DailyPuzzle{}
    |> DailyPuzzle.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, daily_puzzle} ->
        daily_puzzle

      {:error, changeset} ->
        if Keyword.has_key?(changeset.errors, :puzzle_date) do
          get_daily_puzzle(date)
        else
          raise Ecto.InvalidChangesetError, action: :insert, changeset: changeset
        end
    end
  end

  defp daily_puzzle_generator_opts do
    Application.get_env(:black_knight_puzzle, :daily_puzzle_generator, [])
  end

  def save_daily_score(nil, _daily_puzzle, _move_count), do: {:ok, nil}

  def save_daily_score(user, daily_puzzle, move_count) do
    attrs = %{
      user_id: user.id,
      daily_puzzle_id: daily_puzzle.id,
      move_count: move_count,
      solved_at: DateTime.utc_now() |> DateTime.truncate(:second)
    }

    %DailyPuzzleScore{}
    |> DailyPuzzleScore.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, score} ->
        {:ok, score}

      {:error, changeset} ->
        if Keyword.has_key?(changeset.errors, :user_id) do
          {:ok, get_daily_score(user.id, daily_puzzle.id)}
        else
          {:error, changeset}
        end
    end
  end

  def get_daily_score(user_id, daily_puzzle_id) do
    Repo.get_by(DailyPuzzleScore, user_id: user_id, daily_puzzle_id: daily_puzzle_id)
  end

  # database inserts

  def create_user_game(attrs \\ %{}) do
    %UserGame{}
    |> UserGame.changeset(attrs)
    |> Repo.insert()
  end

  def create_user_game_move(attrs \\ %{}) do
    %UserGameMove{}
    |> UserGameMove.changeset(attrs)
    |> Repo.insert()
  end
end
