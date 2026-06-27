defmodule BlackKnightPuzzle.Game.BlackKnightTest do
  use BlackKnightPuzzle.DataCase
  alias BlackKnightPuzzle.Game.BlackKnight
  alias BlackKnightPuzzle.Game.DailyPuzzleGenerator
  alias BlackKnightPuzzle.Game.Solver

  test "set_board/0 returns new board state" do
    board_start_state = BlackKnight.set_board()

    player_value = board_start_state[1][:H]
    end_value = board_start_state[3][:C]

    assert player_value == "P"
    assert end_value == 0
  end

  test "get_board_value_at/2 returns value at move returns start end space" do
    board_state = BlackKnight.set_board()

    result = BlackKnight.get_board_value_at(board_state, "c3")
    assert result == 0
  end

  test "get_board_value_at/2 returns value at first move" do
    board_state = BlackKnight.set_board()

    result = BlackKnight.get_board_value_at(board_state, "c2")
    assert result == "R"
  end

  test "get_move_to_position_string/1 returns move" do
    board_state = BlackKnight.set_board()

    result = BlackKnight.get_move_to_position_string("Rc2c3")
    assert result == "c3"
  end

  test "get_move_from_position_string/1 returns current position" do
    board_state = BlackKnight.set_board()

    result = BlackKnight.get_move_from_position_string("Rc2c3")
    assert result == "c2"
  end

  test "get_move_to_position_string/1 returns error" do
    board_state = BlackKnight.set_board()
    result = BlackKnight.get_move_to_position_string("Rc3")
    assert result == :error
  end

  test "update_position" do
    board_state = BlackKnight.set_board()

    updated_game_state = BlackKnight.update_position(board_state, "Rc2c3")
    from_value = BlackKnight.get_board_value_at(updated_game_state, "c2")
    to_value = BlackKnight.get_board_value_at(updated_game_state, "c3")

    assert from_value == 0
    assert to_value == "R"
  end

  test "is_game_finished/2 returns true" do
    board_state = BlackKnight.set_board()
    updated_state = put_in(board_state[3][:C], "P")

    result = BlackKnight.is_game_finished?(updated_state)

    assert result
  end

  test "is_game_finished?/2 returns false" do
    board_state = BlackKnight.set_board()

    result = BlackKnight.is_game_finished?(board_state)
    refute result
  end

  test "is_move_legal/2 rook returns true for horizontal" do
    board_state = BlackKnight.set_board()

    legal? = BlackKnight.is_move_legal?(board_state, "Rc2C3")

    assert legal?
  end

  test "is_move_legal/2 rook returns true for vertical" do
    board_state = BlackKnight.set_board()

    legal? = BlackKnight.is_move_legal?(board_state, "Rh2g2")

    assert legal?
  end

  test "is_move_legal/2 rook returns false for vertical" do
    board_state = BlackKnight.set_board()

    legal? = BlackKnight.is_move_legal?(board_state, "Rh1g2")

    refute legal?
  end

  test "is_move_legal/2 bishop returns true" do
    board_state = BlackKnight.set_board()

    legal? = BlackKnight.is_move_legal?(board_state, "Bh1g2")

    assert legal?
  end

  test "is_move_legal/2 bishop returns true for edge to edge" do
    board_state = BlackKnight.set_board()

    legal? = BlackKnight.is_move_legal?(board_state, "Bh1d5")

    assert legal?
  end

  test "is_move_legal/2 bishop returns false for horizontal move" do
    board_state = BlackKnight.set_board()

    legal? = BlackKnight.is_move_legal?(board_state, "Bh1h5")

    refute legal?
  end

  test "is_move_legal/2 kight returns false for move" do
    board_state = BlackKnight.set_board()

    legal? = BlackKnight.is_move_legal?(board_state, "Kh1f5")

    refute legal?
  end

  test "is_move_legal/2 kight returns true for move" do
    board_state = BlackKnight.set_board()

    legal? = BlackKnight.is_move_legal?(board_state, "Kh1f2")

    assert legal?
  end

  test "is_move_legal/2 kight returns true for win spot non black knight" do
    board_state = BlackKnight.set_board()

    legal? = BlackKnight.is_move_legal?(board_state, "Kd1c3")

    assert legal?
  end

  test "is_move_legal/2 kight returns true for move middle" do
    board_state = BlackKnight.set_board()

    legal? = BlackKnight.is_move_legal?(board_state, "Ke3g2")

    assert legal?
  end

  test "process_move/3 can finish at a custom goal" do
    board_state =
      BlackKnight.set_board()
      |> put_in([1, :H], "K")
      |> put_in([2, :E], "P")

    assert {:ok, "Game finished", updated_state} =
             BlackKnight.process_move(board_state, "Pe2c3", "c3")

    assert BlackKnight.is_game_finished?(updated_state, "c3")
  end

  test "solver finds the default board solution" do
    assert {:ok, moves} = Solver.solve(BlackKnight.set_board(), "c3", max_depth: 100)
    assert length(moves) == 18
  end

  test "solver returns a shortest one-move solution" do
    board_state =
      BlackKnight.set_board()
      |> put_in([1, :H], "K")
      |> put_in([2, :E], "P")

    assert {:ok, ["Pe2c3"]} = Solver.solve(board_state, "c3", max_depth: 5)
  end

  test "solver returns unsolvable when no solution exists within the depth limit" do
    assert :unsolvable = Solver.solve(BlackKnight.set_board(), "c3", max_depth: 1)
  end

  test "daily puzzle generator creates a stable solvable puzzle for a date" do
    date = ~D[2026-06-27]
    opts = [min_solution_length: 1, max_solution_length: 40, max_attempts: 10]

    puzzle = DailyPuzzleGenerator.generate(date, opts)
    same_puzzle = DailyPuzzleGenerator.generate(date, opts)

    assert puzzle.puzzle_date == date
    assert puzzle.solvable
    assert puzzle.solution_length == length(puzzle.solution_moves)
    assert puzzle.start_state == same_puzzle.start_state
    assert puzzle.goal_position == same_puzzle.goal_position

    assert {:ok, solution_moves} =
             Solver.solve(puzzle.start_state, puzzle.goal_position, max_depth: 40)

    assert solution_moves == puzzle.solution_moves
  end
end
