defmodule BlackKnightPuzzle.Repo.Migrations.AddGamesTable do
  use Ecto.Migration

  def change do
    create table(:games) do
      add :name, :string
      add :start_state, :map

      timestamps()
    end
  end
end
