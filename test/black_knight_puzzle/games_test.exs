defmodule BlackKnightPuzzle.GamesTest do
  use BlackKnightPuzzle.DataCase

  import BlackKnightPuzzle.AccountsFixtures

  alias BlackKnightPuzzle.Game.BlackKnight
  alias BlackKnightPuzzle.Games

  test "get_or_create_daily_puzzle/1 returns the same puzzle for a date" do
    date = ~D[2026-06-27]

    daily_puzzle = Games.get_or_create_daily_puzzle(date)
    same_daily_puzzle = Games.get_or_create_daily_puzzle(date)

    assert daily_puzzle.id == same_daily_puzzle.id
    assert daily_puzzle.puzzle_date == date
    assert daily_puzzle.solvable
  end

  test "get_or_create_daily_puzzle/1 creates different rows for different dates" do
    first_puzzle = Games.get_or_create_daily_puzzle(~D[2026-06-27])
    second_puzzle = Games.get_or_create_daily_puzzle(~D[2026-06-28])

    assert first_puzzle.id != second_puzzle.id
  end

  test "save_daily_score/3 stores only one score per user and daily puzzle" do
    user = user_fixture()
    daily_puzzle = Games.get_or_create_daily_puzzle(~D[2026-06-27])

    assert {:ok, score} = Games.save_daily_score(user, daily_puzzle, 12)
    assert {:ok, same_score} = Games.save_daily_score(user, daily_puzzle, 14)

    assert score.id == same_score.id
    assert same_score.move_count == 12
  end

  test "saved user game won flag can stay false after a non-winning move" do
    user = user_fixture()

    {:ok, user_game} =
      Games.create_user_game(%{
        user_id: user.id,
        game_id: user.id,
        current_state: BlackKnight.set_board()
      })

    {:ok, updated_user_game} =
      Games.update_user_game(user_game.id, %{
        current_state: BlackKnight.update_position(BlackKnight.set_board(), "Rc2c3")
      })

    refute updated_user_game.won
  end
end
