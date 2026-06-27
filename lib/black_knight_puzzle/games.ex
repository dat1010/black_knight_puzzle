defmodule BlackKnightPuzzle.Games do
  @moduledoc """
  The Games context.
  """
  import Ecto.Query, warn: false
  alias Ecto.Repo
  alias BlackKnightPuzzle.Repo

  alias BlackKnightPuzzle.Games.Game
  alias BlackKnightPuzzle.Games.DailyPuzzle
  alias BlackKnightPuzzle.Games.DailyPuzzleScore
  alias BlackKnightPuzzle.Games.UserGame
  alias BlackKnightPuzzle.Games.UserGameMove
  alias BlackKnightPuzzle.Game.DailyPuzzleGenerator

  # database getters

  @doc """
  Gets a single game by name

  ## Examples

    iex> get_game_by_name("BlackKnightPuzzle")
    $Game{}

  """
  def get_game_by_name(name) do
    query =
      from g in Game,
        where: g.name == ^name

    query
    |> Repo.all()
    |> hd()
  end

  @doc """
  Gets a single user game by ID.

  ## Examples

      iex> get_user_game_by_id(123)
      %UserGame{id: 123, ...}

      iex> get_user_game_by_id(456)
      nil

  """
  def get_user_game_by_id(user_game_id) do
    from(g in UserGame,
      where: g.id == ^user_game_id,
      preload: [:user_game_moves]
    )
    |> Repo.all()
    |> hd
  end

  @doc """
  Gets all games for a specific user id

  ## Examples

    iex> list_user_games_by_user_id(1)
    %UserGame{}

    iex> list_user_games_by_user_id(341234)
    []
  """
  def list_user_games_by_user_id(user_id) do
    from(g in UserGame,
      where: g.user_id == ^user_id,
      order_by: [desc: g.updated_at],
      preload: [:user_game_moves]
    )
    |> Repo.all()
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

  # database update
  def update_user_game(id, attrs \\ %{}) do
    UserGame
    # Get the existing UserGame based on the ID provided
    |> Repo.get(id)
    |> case do
      nil ->
        {:error, :not_found}

      user_game ->
        user_game
        |> UserGame.changeset(attrs)
        |> Repo.update()
    end
  end
end
