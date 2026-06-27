defmodule BlackKnightPuzzle.Games.DailyPuzzle do
  use Ecto.Schema
  import Ecto.Changeset

  schema "daily_puzzles" do
    field :puzzle_date, :date
    field :seed, :string
    field :start_state, :map
    field :goal_position, :string
    field :solution_moves, {:array, :string}, default: []
    field :solution_length, :integer
    field :solvable, :boolean, default: false

    has_many :daily_puzzle_scores, BlackKnightPuzzle.Games.DailyPuzzleScore

    timestamps()
  end

  def changeset(daily_puzzle, attrs) do
    daily_puzzle
    |> cast(attrs, [
      :puzzle_date,
      :seed,
      :start_state,
      :goal_position,
      :solution_moves,
      :solution_length,
      :solvable
    ])
    |> validate_required([
      :puzzle_date,
      :seed,
      :start_state,
      :goal_position,
      :solution_moves,
      :solution_length,
      :solvable
    ])
    |> unique_constraint(:puzzle_date)
  end
end
