defmodule BlackKnightPuzzle.Repo.Migrations.AddWonColumnToUserGames do
  use Ecto.Migration

  def change do
    alter table(:user_games) do
      add :won, :boolean, default: false
    end
  end
end
