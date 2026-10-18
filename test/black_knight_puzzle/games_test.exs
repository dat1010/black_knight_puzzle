defmodule BlackKnightPuzzle.GamesTest do
  use BlackKnightPuzzle.DataCase

  import BlackKnightPuzzle.AccountsFixtures
  import BlackKnightPuzzle.GamesFixtures

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

  test "get_or_create_daily_puzzle/1 returns an existing puzzle without generating" do
    daily_puzzle = daily_puzzle_fixture(~D[2026-06-27])

    assert Games.get_or_create_daily_puzzle(~D[2026-06-27]).id == daily_puzzle.id
  end

  test "get_or_create_daily_puzzle/1 creates different rows for different dates" do
    first_puzzle = Games.get_or_create_daily_puzzle(~D[2026-06-27])
    second_puzzle = Games.get_or_create_daily_puzzle(~D[2026-06-28])

    assert first_puzzle.id != second_puzzle.id
  end

  test "save_daily_score/3 stores only one score per user and daily puzzle" do
    user = user_fixture()
    daily_puzzle = daily_puzzle_fixture(~D[2026-06-27])

    assert {:ok, score} = Games.save_daily_score(user, daily_puzzle, 12)
    assert {:ok, same_score} = Games.save_daily_score(user, daily_puzzle, 14)

    assert score.id == same_score.id
    assert same_score.move_count == 12
  end

  test "ensure_daily_puzzles/2 creates puzzles for the date and the days after it" do
    daily_puzzle_fixture(~D[2026-06-28])

    assert Games.ensure_daily_puzzles(~D[2026-06-27], 2) ==
             [~D[2026-06-27], ~D[2026-06-28], ~D[2026-06-29]]

    for date <- [~D[2026-06-27], ~D[2026-06-28], ~D[2026-06-29]] do
      assert Games.get_daily_puzzle(date)
    end
  end

  describe "user games" do
    test "start_user_game/1 creates a classic game for the user" do
      user = user_fixture()

      assert {:ok, user_game} = Games.start_user_game(user)
      assert user_game.user_id == user.id
      assert user_game.game_id == Games.get_classic_game!().id
      refute user_game.won
    end

    test "list_user_games/1 only returns the user's own games" do
      user = user_fixture()
      other_user = user_fixture()
      {:ok, mine} = Games.start_user_game(user)
      {:ok, _theirs} = Games.start_user_game(other_user)

      assert [%{id: id}] = Games.list_user_games(user)
      assert id == mine.id
    end

    test "get_user_game!/2 raises for another user's game" do
      {:ok, theirs} = Games.start_user_game(user_fixture())

      assert_raise Ecto.NoResultsError, fn ->
        Games.get_user_game!(user_fixture(), theirs.id)
      end
    end

    test "record_user_game_move/4 keeps won false after a non-winning move" do
      {:ok, user_game} = Games.start_user_game(user_fixture())
      new_state = BlackKnight.update_position(BlackKnight.set_board(), "Rc2c3")

      assert {:ok, user_game} = Games.record_user_game_move(user_game, "Rc2c3", new_state, false)
      refute user_game.won
      assert user_game.current_state == new_state
    end

    test "record_user_game_move/4 marks the game won" do
      {:ok, user_game} = Games.start_user_game(user_fixture())

      assert {:ok, user_game} =
               Games.record_user_game_move(user_game, "Pe2c3", BlackKnight.set_board(), true)

      assert user_game.won
    end
  end
end
