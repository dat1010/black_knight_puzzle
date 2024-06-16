defmodule BlackKnightPuzzle.Games do
  @moduledoc """
  The Games context.
  """
  import Ecto.Query, warn: false
  alias Ecto.Repo
  alias BlackKnightPuzzle.Repo

  alias BlackKnightPuzzle.Games.Game
  alias BlackKnightPuzzle.Games.UserGame
  alias BlackKnightPuzzle.Games.UserGameMove

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
