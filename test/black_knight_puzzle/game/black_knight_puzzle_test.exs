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
    result = BlackKnight.get_move_to_position_string("Rc2c3")
    assert result == "c3"
  end

  test "get_move_from_position_string/1 returns current position" do
    result = BlackKnight.get_move_from_position_string("Rc2c3")
    assert result == "c2"
  end

  test "get_move_to_position_string/1 returns error" do
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

  # Starting board (set_board/0):
  #      H  G  F  E  D  C
  #   1 [P][B][B][B][B][R]
  #   2 [K][K][K][K][R][R]
  #   3 [x][x][x][x][R][0]

  test "is_move_legal/2 rook returns true for horizontal" do
    assert BlackKnight.is_move_legal?(BlackKnight.set_board(), "Rd3c3")
  end

  test "is_move_legal/2 rook returns true for vertical" do
    assert BlackKnight.is_move_legal?(BlackKnight.set_board(), "Rc2c3")
  end

  test "is_move_legal/2 rook returns false for diagonal" do
    board_state = put_in(BlackKnight.set_board(), [2, :E], 0)

    refute BlackKnight.is_move_legal?(board_state, "Rd3e2")
  end

  test "is_move_legal/2 rook cannot pass through a piece" do
    board_state =
      BlackKnight.set_board()
      |> put_in([3, :C], "R")
      |> put_in([1, :C], 0)

    refute BlackKnight.is_move_legal?(board_state, "Rc3c1")
  end

  test "is_move_legal/2 bishop returns true" do
    board_state = put_in(BlackKnight.set_board(), [2, :H], 0)

    assert BlackKnight.is_move_legal?(board_state, "Bg1h2")
  end

  test "is_move_legal/2 bishop returns true for edge to edge" do
    board_state =
      BlackKnight.set_board()
      |> put_in([2, :E], 0)
      |> put_in([3, :D], 0)

    assert BlackKnight.is_move_legal?(board_state, "Bf1d3")
  end

  test "is_move_legal/2 bishop cannot pass through a piece" do
    board_state = put_in(BlackKnight.set_board(), [3, :D], 0)

    refute BlackKnight.is_move_legal?(board_state, "Bf1d3")
  end

  test "is_move_legal/2 bishop returns false for horizontal move" do
    board_state = put_in(BlackKnight.set_board(), [1, :E], 0)

    refute BlackKnight.is_move_legal?(board_state, "Bf1e1")
  end

  test "is_move_legal/2 knight returns false for non-L move" do
    board_state = put_in(BlackKnight.set_board(), [2, :E], 0)

    refute BlackKnight.is_move_legal?(board_state, "Kh2e2")
  end

  test "is_move_legal/2 knight returns true for move" do
    board_state = put_in(BlackKnight.set_board(), [1, :F], 0)

    assert BlackKnight.is_move_legal?(board_state, "Kh2f1")
  end

  test "is_move_legal/2 knight returns true for win spot non black knight" do
    assert BlackKnight.is_move_legal?(BlackKnight.set_board(), "Ke2c3")
  end

  test "is_move_legal/2 knight can jump over pieces" do
    board_state = put_in(BlackKnight.set_board(), [1, :G], 0)

    assert BlackKnight.is_move_legal?(board_state, "Ke2g1")
  end

  test "is_move_legal/2 returns false when the target is occupied" do
    refute BlackKnight.is_move_legal?(BlackKnight.set_board(), "Kh2f1")
  end

  describe "forged and malformed moves" do
    test "a piece cannot move as a different piece type" do
      # d3 holds a rook; sending it as a knight or the player must not work.
      board_state = put_in(BlackKnight.set_board(), [1, :C], 0)

      refute BlackKnight.is_move_legal?(board_state, "Kd3c1")
      refute BlackKnight.is_move_legal?(board_state, "Pd3c1")

      assert {:error, "Illegal move", ^board_state} =
               BlackKnight.process_move(board_state, "Kd3c1")
    end

    test "the blocked squares cannot be moved" do
      board_state = put_in(BlackKnight.set_board(), [2, :F], 0)

      assert {:error, "Illegal move", ^board_state} =
               BlackKnight.process_move(board_state, "Kh3f2")

      assert {:error, "Illegal move", ^board_state} =
               BlackKnight.process_move(board_state, "xh3f2")
    end

    test "an empty square cannot be moved" do
      board_state = BlackKnight.set_board()

      refute BlackKnight.is_move_legal?(board_state, "Kc3e2")
      refute BlackKnight.is_move_legal?(board_state, "0c3e2")
    end

    test "nothing can move onto a blocked square" do
      # h2 -> f3 is a knight's L, but f3 is blocked.
      refute BlackKnight.is_move_legal?(BlackKnight.set_board(), "Kh2f3")
    end

    test "malformed moves are rejected without raising" do
      board_state = BlackKnight.set_board()

      for move <- ["", "R", "Rc2", "Rc2c", "Rc2c3x", "Rz2c3", "Rc9c3", "Rc0c3", "Qc2c3", "Rc2Z3"] do
        assert {:error, "Illegal move", ^board_state} =
                 BlackKnight.process_move(board_state, move)
      end
    end
  end

  test "parse_move/1 accepts board squares in either case" do
    assert {:ok, "R", "c2", "c3"} = BlackKnight.parse_move("Rc2C3")
    assert :error = BlackKnight.parse_move("Rc4c3")
    assert :error = BlackKnight.parse_move("Rb2c3")
  end

  test "build_move/5 rejects non-string params" do
    assert "Rc2c3" = BlackKnight.build_move("2", "C", "R", "3", "C")
    assert :error = BlackKnight.build_move(2, "C", "R", "3", "C")
    assert :error = BlackKnight.build_move(nil, "C", "R", "3", %{})
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

  test "daily puzzle generator fallback solution is the solver's shortest solution" do
    assert {:ok, moves} = Solver.solve(BlackKnight.set_board(), "c3", max_depth: 100)
    assert moves == DailyPuzzleGenerator.default_solution()
  end

  test "daily puzzle generator creates a stable solvable puzzle for a date" do
    date = ~D[2026-06-27]
    opts = [min_solution_length: 1, max_solution_length: 5, max_attempts: 5]

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
