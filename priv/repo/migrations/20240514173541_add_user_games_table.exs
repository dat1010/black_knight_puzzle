defmodule BlackKnightPuzzle.Repo.Migrations.AddUserGamesTable do
  use Ecto.Migration

  def change do
    create table(:user_games) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :game_id, references(:users, on_delete: :nothing), null: false
      add :current_state, :map

      timestamps()
    end
  end
end
