defmodule BlackKnightPuzzle.Game.Solver do
  @moduledoc """
  Finds shortest Black Knight puzzle solutions using breadth-first search.
  """

  alias BlackKnightPuzzle.Game.BlackKnight

  @default_max_depth 40

  def solve(game_state, goal_position, opts \\ []) do
    max_depth = Keyword.get(opts, :max_depth, @default_max_depth)
    game_state = BlackKnight.normalize_game_state(game_state)

    cond do
      BlackKnight.is_game_finished?(game_state, goal_position) ->
        {:ok, []}

      max_depth < 1 ->
        :unsolvable

      true ->
        search(game_state, goal_position, max_depth)
    end
  end

  def legal_moves(game_state) do
    game_state = BlackKnight.normalize_game_state(game_state)
    open_positions = positions_with_value(game_state, 0)

    for {from_position, piece} <- pieces(game_state),
        to_position <- open_positions,
        move = "#{piece}#{from_position}#{to_position}",
        BlackKnight.is_move_legal?(game_state, move) do
      move
    end
  end

  defp search(game_state, goal_position, max_depth) do
    queue = :queue.from_list([{game_state, []}])
    visited = MapSet.new([state_key(game_state)])

    bfs(queue, visited, goal_position, max_depth)
  end

  defp bfs(queue, visited, goal_position, max_depth) do
    case :queue.out(queue) do
      {:empty, _queue} ->
        :unsolvable

      {{:value, {game_state, path}}, queue} ->
        if length(path) >= max_depth do
          bfs(queue, visited, goal_position, max_depth)
        else
          {queue, visited, result} =
            game_state
            |> legal_moves()
            |> Enum.reduce_while({queue, visited, nil}, fn move, {queue, visited, _result} ->
              {:ok, _message, next_state} =
                BlackKnight.process_move(game_state, move, goal_position)

              key = state_key(next_state)

              if MapSet.member?(visited, key) do
                {:cont, {queue, visited, nil}}
              else
                next_path = [move | path]

                if BlackKnight.is_game_finished?(next_state, goal_position) do
                  {:halt, {queue, visited, {:ok, Enum.reverse(next_path)}}}
                else
                  {:cont,
                   {:queue.in({next_state, next_path}, queue), MapSet.put(visited, key), nil}}
                end
              end
            end)

          case result do
            {:ok, moves} -> {:ok, moves}
            nil -> bfs(queue, visited, goal_position, max_depth)
          end
        end
    end
  end

  defp pieces(game_state) do
    for row <- BlackKnight.rows(),
        col <- BlackKnight.columns(),
        value = game_state[row][col],
        is_binary(value),
        value != "x" do
      {BlackKnight.position_string(row, col), value}
    end
  end

  defp positions_with_value(game_state, target_value) do
    for row <- BlackKnight.rows(),
        col <- BlackKnight.columns(),
        game_state[row][col] == target_value do
      BlackKnight.position_string(row, col)
    end
  end

  defp state_key(game_state) do
    game_state
    |> BlackKnight.normalize_game_state()
    |> Enum.sort_by(fn {row, _cols} -> row end)
    |> Enum.flat_map(fn {row, cols} ->
      cols
      |> Enum.sort_by(fn {col, _value} -> BlackKnight.value_map()[col] end)
      |> Enum.map(fn {col, value} -> {row, col, value} end)
    end)
    |> :erlang.term_to_binary()
  end
end
