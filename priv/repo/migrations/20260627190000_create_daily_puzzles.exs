defmodule BlackKnightPuzzle.Repo.Migrations.CreateDailyPuzzles do
  use Ecto.Migration

  def change do
    create table(:daily_puzzles) do
      add :puzzle_date, :date, null: false
      add :seed, :string, null: false
      add :start_state, :map, null: false
      add :goal_position, :string, null: false
      add :solution_moves, {:array, :string}, null: false, default: []
      add :solution_length, :integer, null: false
      add :solvable, :boolean, null: false, default: false

      timestamps()
    end

    create unique_index(:daily_puzzles, [:puzzle_date])
  end
end
