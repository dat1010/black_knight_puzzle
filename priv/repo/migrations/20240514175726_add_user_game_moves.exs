defmodule BlackKnightPuzzle.Repo.Migrations.AddUserGameMoves do
  use Ecto.Migration

  def change do
    create table(:user_game_moves) do
      add :user_game_id, references(:user_games, on_delete: :delete_all), null: false
      add :move, :string, null: false

      timestamps()
    end
  end
end
