defmodule BlackKnightPuzzle.Repo.Migrations.CreateDailyPuzzleScores do
  use Ecto.Migration

  def change do
    create table(:daily_puzzle_scores) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :daily_puzzle_id, references(:daily_puzzles, on_delete: :delete_all), null: false
      add :move_count, :integer, null: false
      add :solved_at, :utc_datetime, null: false

      timestamps()
    end

    create unique_index(:daily_puzzle_scores, [:user_id, :daily_puzzle_id])
  end
end
