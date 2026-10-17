defmodule BlackKnightPuzzle.GamesFixtures do
  @moduledoc """
  Test helpers for creating entities via the `BlackKnightPuzzle.Games` context.
  """

  alias BlackKnightPuzzle.Game.BlackKnight
  alias BlackKnightPuzzle.Game.DailyPuzzleGenerator
  alias BlackKnightPuzzle.Games.DailyPuzzle
  alias BlackKnightPuzzle.Repo

  @doc """
  Inserts a daily puzzle for `date` using the default board, so tests never
  run the BFS generator.
  """
  def daily_puzzle_fixture(date \\ Date.utc_today(), attrs \\ %{}) do
    solution = DailyPuzzleGenerator.default_solution()

    %DailyPuzzle{}
    |> DailyPuzzle.changeset(
      Enum.into(attrs, %{
        puzzle_date: date,
        seed: "fixture",
        start_state: BlackKnight.set_board(),
        goal_position: "c3",
        solution_moves: solution,
        solution_length: length(solution),
        solvable: true
      })
    )
    |> Repo.insert!()
  end
end
