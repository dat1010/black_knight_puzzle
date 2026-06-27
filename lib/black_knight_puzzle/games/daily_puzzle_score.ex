defmodule BlackKnightPuzzle.Games.DailyPuzzleScore do
  use Ecto.Schema
  import Ecto.Changeset

  schema "daily_puzzle_scores" do
    field :move_count, :integer
    field :solved_at, :utc_datetime

    belongs_to :user, BlackKnightPuzzle.Accounts.User
    belongs_to :daily_puzzle, BlackKnightPuzzle.Games.DailyPuzzle

    timestamps()
  end

  def changeset(daily_puzzle_score, attrs) do
    daily_puzzle_score
    |> cast(attrs, [:user_id, :daily_puzzle_id, :move_count, :solved_at])
    |> validate_required([:user_id, :daily_puzzle_id, :move_count, :solved_at])
    |> validate_number(:move_count, greater_than: 0)
    |> unique_constraint([:user_id, :daily_puzzle_id])
  end
end
