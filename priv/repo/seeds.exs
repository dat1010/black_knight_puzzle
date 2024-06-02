# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     BlackKnightPuzzle.Repo.insert!(%BlackKnightPuzzle.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

BlackKnightPuzzle.Games.Game.changeset(%BlackKnightPuzzle.Games.Game{}, %{
  name: "BlackKnightPuzzle",
  start_state: BlackKnightPuzzle.Game.BlackKnight.set_board()
})
|> BlackKnightPuzzle.Repo.insert()
