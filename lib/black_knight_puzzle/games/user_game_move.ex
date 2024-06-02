defmodule BlackKnightPuzzle.Games.UserGameMove do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_game_moves" do
    field :move, :string
    belongs_to :user_game, BlackKnightPuzzle.Games.UserGame

    timestamps()
  end

  def changeset(user_game_move, attrs) do
    user_game_move
    |> cast(attrs, [:user_game_id, :move])
    |> validate_required([:user_game_id, :move])
  end
end
