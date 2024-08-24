defmodule BlackKnightPuzzle.Games.UserGame do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_games" do
    field :current_state, :map
    field :won, :boolean, default: false
    belongs_to :user, BlackKnightPuzzle.Accounts.User
    belongs_to :game, BlackKnightPuzzle.Games.Game
    has_many :user_game_moves, BlackKnightPuzzle.Games.UserGameMove

    timestamps()
  end

  def changeset(user_game, attrs) do
    user_game
    |> cast(attrs, [:user_id, :game_id, :current_state, :won])
    |> validate_required([:user_id, :game_id])
    |> cast_assoc(:user_game_moves)
  end
end
