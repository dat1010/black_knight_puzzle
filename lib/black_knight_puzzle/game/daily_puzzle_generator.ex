defmodule BlackKnightPuzzle.Game.DailyPuzzleGenerator do
  @moduledoc """
  Builds one deterministic, BFS-verified puzzle candidate for a date.
  """

  alias BlackKnightPuzzle.Game.BlackKnight
  alias BlackKnightPuzzle.Game.Solver

  @min_solution_length 10
  @max_solution_length 40
  @max_attempts 200
  @pieces ["P", "K", "K", "K", "K", "B", "B", "B", "B", "R", "R", "R", "R"]

  def generate(date, opts \\ []) do
    min_length = Keyword.get(opts, :min_solution_length, @min_solution_length)
    max_length = Keyword.get(opts, :max_solution_length, @max_solution_length)
    max_attempts = Keyword.get(opts, :max_attempts, @max_attempts)
    seed = Keyword.get(opts, :seed, seed_for_date(date))
    rand_state = :rand.seed_s(:exsplus, seed)

    {candidate, _rand_state} =
      Enum.reduce_while(1..max_attempts, {nil, rand_state}, fn _attempt, {best, rand_state} ->
        {board, goal_position, rand_state} = random_board(rand_state)

        case Solver.solve(board, goal_position, max_depth: max_length) do
          {:ok, solution_moves} ->
            solution_length = length(solution_moves)
            candidate = candidate_attrs(date, seed, board, goal_position, solution_moves)
            best = better_candidate(best, candidate)

            if solution_length >= min_length and solution_length <= max_length do
              {:halt, {candidate, rand_state}}
            else
              {:cont, {best, rand_state}}
            end

          :unsolvable ->
            {:cont, {best, rand_state}}
        end
      end)

    case candidate do
      nil ->
        fallback_board = BlackKnight.set_board()
        {:ok, solution_moves} = Solver.solve(fallback_board, "c3", max_depth: 100)
        candidate_attrs(date, seed, fallback_board, "c3", solution_moves)

      candidate ->
        candidate
    end
  end

  def seed_for_date(%Date{} = date) do
    days = Date.to_gregorian_days(date)
    {days, days * 31, days * 131}
  end

  defp random_board(rand_state) do
    {goal_position, rand_state} = random_member(BlackKnight.playable_positions(), rand_state)
    piece_positions = BlackKnight.playable_positions() -- [goal_position]
    {shuffled_pieces, rand_state} = shuffle(@pieces, rand_state)

    board =
      BlackKnight.set_board()
      |> put_position(goal_position, 0)

    board =
      Enum.zip(piece_positions, shuffled_pieces)
      |> Enum.reduce(board, fn {position, piece}, board ->
        put_position(board, position, piece)
      end)

    {board, goal_position, rand_state}
  end

  defp candidate_attrs(date, seed, board, goal_position, solution_moves) do
    %{
      puzzle_date: date,
      seed: seed |> Tuple.to_list() |> Enum.join(":"),
      start_state: board,
      goal_position: goal_position,
      solution_moves: solution_moves,
      solution_length: length(solution_moves),
      solvable: true
    }
  end

  defp better_candidate(nil, candidate), do: candidate

  defp better_candidate(best, candidate) do
    if candidate.solution_length > best.solution_length do
      candidate
    else
      best
    end
  end

  defp put_position(board, position, value) do
    row = BlackKnight.get_row_integer(position)
    col = BlackKnight.get_column_atom(position)

    put_in(board, [row, col], value)
  end

  defp random_member(list, rand_state) do
    {index, rand_state} = :rand.uniform_s(length(list), rand_state)
    {Enum.at(list, index - 1), rand_state}
  end

  defp shuffle(list, rand_state) do
    {decorated, rand_state} =
      Enum.map_reduce(list, rand_state, fn value, rand_state ->
        {rank, rand_state} = :rand.uniform_s(rand_state)
        {{rank, value}, rand_state}
      end)

    shuffled =
      decorated
      |> Enum.sort_by(fn {rank, _value} -> rank end)
      |> Enum.map(fn {_rank, value} -> value end)

    {shuffled, rand_state}
  end
end
