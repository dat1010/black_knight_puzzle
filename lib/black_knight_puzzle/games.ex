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
