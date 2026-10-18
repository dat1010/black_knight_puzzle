defmodule BlackKnightPuzzle.Game.Solver do
  @moduledoc """
  Finds shortest Black Knight puzzle solutions using breadth-first search.

  Internally a board is a flat 18-element tuple, row-major from H1 to C3, so
  each search step is tuple lookups instead of rebuilding nested maps. Moves
  follow the same rules as `BlackKnight.is_move_legal?/2` and are generated
  in the same order, so results match a search over the map representation.
  """

  alias BlackKnightPuzzle.Game.BlackKnight

  @default_max_depth 40
  @default_max_states 500_000
  # How many positions to expand between deadline checks.
  @deadline_check_interval 1_024

  @columns BlackKnight.columns()
  @rows BlackKnight.rows()
  @width length(@columns)
  @cells length(@rows) * @width
  @pieces ["P", "K", "B", "R"]

  @squares (for row <- @rows, col <- @columns do
              BlackKnight.position_string(row, col)
            end)
           |> List.to_tuple()

  @doc """
  Solves `game_state` for the black knight reaching `goal_position`.

  ## Options

    * `:max_depth` - the longest solution to look for (default #{@default_max_depth})
    * `:max_states` - give up after visiting this many positions
      (default #{@default_max_states})
    * `:deadline` - a `System.monotonic_time(:millisecond)` after which to give up

  Returns `{:ok, moves}` with a shortest solution, or `:unsolvable` if none is
  found within the limits.
  """
  def solve(game_state, goal_position, opts \\ []) do
    board = to_board(game_state)
    goal = square_index(goal_position)

    limits = %{
      max_depth: Keyword.get(opts, :max_depth, @default_max_depth),
      max_states: Keyword.get(opts, :max_states, @default_max_states),
      deadline: Keyword.get(opts, :deadline)
    }

    cond do
      elem(board, goal) == "P" -> {:ok, []}
      limits.max_depth < 1 -> :unsolvable
      true -> search(board, goal, limits)
    end
  end

  def legal_moves(game_state) do
    game_state
    |> to_board()
    |> board_moves()
    |> Enum.map(fn {move, _next_board} -> move end)
  end

  defp search(board, goal, limits) do
    queue = :queue.from_list([{board, 0, []}])
    visited = MapSet.new([board])

    bfs(queue, visited, goal, limits, 0)
  end

  defp bfs(queue, visited, goal, limits, expanded) do
    cond do
      MapSet.size(visited) > limits.max_states ->
        :unsolvable

      rem(expanded, @deadline_check_interval) == 0 and past_deadline?(limits.deadline) ->
        :unsolvable

      true ->
        case :queue.out(queue) do
          {:empty, _queue} ->
            :unsolvable

          {{:value, {_board, depth, _path}}, queue} when depth >= limits.max_depth ->
            bfs(queue, visited, goal, limits, expanded + 1)

          {{:value, {board, depth, path}}, queue} ->
            board
            |> board_moves()
            |> expand(queue, visited, goal, depth, path)
            |> case do
              {:ok, moves} -> {:ok, moves}
              {queue, visited} -> bfs(queue, visited, goal, limits, expanded + 1)
            end
        end
    end
  end

  defp expand([], queue, visited, _goal, _depth, _path), do: {queue, visited}

  defp expand([{move, next_board} | rest], queue, visited, goal, depth, path) do
    cond do
      MapSet.member?(visited, next_board) ->
        expand(rest, queue, visited, goal, depth, path)

      elem(next_board, goal) == "P" ->
        {:ok, Enum.reverse([move | path])}

      true ->
        queue = :queue.in({next_board, depth + 1, [move | path]}, queue)
        expand(rest, queue, MapSet.put(visited, next_board), goal, depth, path)
    end
  end

  defp past_deadline?(nil), do: false
  defp past_deadline?(deadline), do: System.monotonic_time(:millisecond) >= deadline

  # Every legal move from `board` as {move_string, next_board}, ordered by
  # piece square then target square (both row-major), like the map version.
  defp board_moves(board) do
    holes = for i <- 0..(@cells - 1), elem(board, i) == 0, do: i

    for from <- 0..(@cells - 1),
        piece = elem(board, from),
        piece in @pieces,
        to <- holes,
        legal?(board, piece, from, to) do
      move = piece <> elem(@squares, from) <> elem(@squares, to)
      {move, board |> put_elem(to, piece) |> put_elem(from, 0)}
    end
  end

  defp legal?(_board, piece, from, to) when piece in ["P", "K"] do
    {dr, dc} = delta(from, to)
    {abs(dr), abs(dc)} in [{1, 2}, {2, 1}]
  end

  defp legal?(board, "B", from, to) do
    {dr, dc} = delta(from, to)
    abs(dr) == abs(dc) and path_clear?(board, from, dr, dc)
  end

  defp legal?(board, "R", from, to) do
    {dr, dc} = delta(from, to)
    (dr == 0 or dc == 0) and path_clear?(board, from, dr, dc)
  end

  defp delta(from, to) do
    {div(to, @width) - div(from, @width), rem(to, @width) - rem(from, @width)}
  end

  # True if every square strictly between `from` and the target is empty.
  defp path_clear?(board, from, dr, dc) do
    steps = max(abs(dr), abs(dc))
    step = sign(dr) * @width + sign(dc)

    Enum.all?(1..(steps - 1)//1, fn i -> elem(board, from + i * step) == 0 end)
  end

  defp sign(0), do: 0
  defp sign(n) when n > 0, do: 1
  defp sign(_n), do: -1

  defp to_board(game_state) do
    game_state = BlackKnight.normalize_game_state(game_state)

    for(row <- @rows, col <- @columns, do: game_state[row][col])
    |> List.to_tuple()
  end

  defp square_index(position) do
    position = String.downcase(position)
    Enum.find_index(Tuple.to_list(@squares), &(&1 == position))
  end
end
