defmodule BlackKnightPuzzle.Repo.Migrations.FixUserGamesGameReference do
  use Ecto.Migration

  # user_games.game_id was created as a foreign key to users instead of games.
  # This points it at the games table, makes sure the classic game row exists
  # (production never ran seeds.exs), and moves every user game onto it.
  #
  # It also recomputes `won`: a bug marked games as won after any drag-and-drop
  # move. A classic game is won when the black knight ("P") is on C3.

  @start_state ~s({"1":{"C":"R","D":"B","E":"B","F":"B","G":"B","H":"P"},) <>
                 ~s("2":{"C":"R","D":"R","E":"K","F":"K","G":"K","H":"K"},) <>
                 ~s("3":{"C":0,"D":"R","E":"x","F":"x","G":"x","H":"x"}})

  def up do
    execute """
    INSERT INTO games (name, start_state, inserted_at, updated_at)
    SELECT 'BlackKnightPuzzle', '#{@start_state}'::jsonb, now(), now()
    WHERE NOT EXISTS (SELECT 1 FROM games WHERE name = 'BlackKnightPuzzle')
    """

    execute "ALTER TABLE user_games DROP CONSTRAINT IF EXISTS user_games_game_id_fkey"

    execute """
    UPDATE user_games
    SET game_id = (SELECT min(id) FROM games WHERE name = 'BlackKnightPuzzle')
    """

    alter table(:user_games) do
      modify :game_id, references(:games, on_delete: :restrict), null: false
    end

    create_if_not_exists index(:user_games, [:user_id])

    execute """
    UPDATE user_games
    SET won = COALESCE(current_state -> '3' ->> 'C' = 'P', false)
    """
  end

  # The old game_id values were user ids and can't be restored, so rolling back
  # only removes the games constraint rather than re-adding the wrong one.
  def down do
    execute "ALTER TABLE user_games DROP CONSTRAINT IF EXISTS user_games_game_id_fkey"
  end
end
