defmodule BlackKnightPuzzle.Game.BlackKnight do
  @moduledoc """
  This module processes the Black Knight puzzle's logic, focusing on managing and validating moves for specific chess pieces.
  It does not solve the puzzle but instead checks the legality of moves and determines the game state,
  indicating whether the player has won, the game is unfinished, or a move is illegal.

  The chess pieces included on the board are:
  1. One Black Knight (Player)
  2. Four White Knights
  3. Four White Bishops
  4. Four White Rooks
  A total of 13 pieces are present.
  A total of 13 pieces are present.

  The puzzle is set on a 3x6 grid, with the bottom left five cells marked as unavailable:
  0  H  G  F  E  D  C
  1 [P][B][B][B][B][R]
  2 [K][K][K][K][R][R]
  3 [x][x][x][x][R][0]

  Key
  - P: Player (Black Knight)
  - K: White Knight
  - R: Rook
  - B: Bishop
  - x: Unavailable space
  - 0: Free space (goal)

  Moves are restricted to those that are standard for each chess piece, and the player's objective is to move
  the Black Knight to the free space at the bottom right of the grid to win the puzzle.
  """

  @doc """
  Processes a move in the game.

  This function takes a `move` and the current `game_map` and processes the move by first checking if the move is legal.
  If the move is illegal, it returns an error tuple with a reason. If the move is legal, it updates the game map,
  and checks whether the game has finished. Depending on the game's state, it returns a tuple indicating the game's
  completion status and the updated game map.

  ## Parameters
  - `game_map`: The current state of the game map before the move.
  - `move`: The move to be processed. Expected to be a string representing a move. IE "Rc1c2"

  ## Returns
  - `{:ok, message, new_game_map}`: When the move is processed successfully. `message` will be "Game finished" or "Move processed".
  - `{:error, reason, game_map}`: When the move is illegal. `reason` provides detail about why the move was rejected.

  ## Examples

      iex> BlackKnight.process_move(%{}, "Ke2e4")
      {:ok, "Move processed", %{}}

      iex> BlackKnight.process_move(%{}, "invalid")
      {:error, "Illegal move", %{}}
  """
  def process_move(game_state, move, winning_spot \\ "c3") do
    if is_move_legal?(game_state, move) do
      updated_game_state = update_position(game_state, move)
      check_game_completion(updated_game_state, winning_spot)
    else
      {:error, "Illegal move", game_state}
    end
  end

  defp check_game_completion(game_state, winning_spot) do
    if is_game_finished?(game_state, winning_spot) do
      {:ok, "Game finished", game_state}
    else
      {:ok, "Move processed", game_state}
    end
  end

  def set_board() do
    %{
      1 => %{H: "P", G: "B", F: "B", E: "B", D: "B", C: "R"},
      2 => %{H: "K", G: "K", F: "K", E: "K", D: "R", C: "R"},
      3 => %{H: "x", G: "x", F: "x", E: "x", D: "R", C: 0}
    }
  end

  def value_map() do
    %{H: 1, G: 2, F: 3, E: 4, D: 5, C: 6}
  end

  def columns do
    [:H, :G, :F, :E, :D, :C]
  end

  def rows do
    [1, 2, 3]
  end

  def playable_positions do
    for row <- rows(),
        col <- columns(),
        get_in(set_board(), [row, col]) != "x" do
      position_string(row, col)
    end
  end

  def position_string(row, col) when is_atom(col) do
    "#{Atom.to_string(col) |> String.downcase()}#{row}"
  end

  def normalize_game_state(game_state) do
    Map.new(game_state, fn {row, cols} ->
      normalized_row =
        case row do
          row when is_integer(row) -> row
          row when is_binary(row) -> String.to_integer(row)
        end

      normalized_cols =
        Map.new(cols, fn {col, value} ->
          normalized_col =
            case col do
              col when is_atom(col) -> col
              col when is_binary(col) -> String.to_atom(col)
            end

          {normalized_col, value}
        end)

      {normalized_row, normalized_cols}
    end)
  end

  @doc """
  updates the current game state with the new position
  """
  def update_position(game_state, move) do
    {:ok, _piece, from, to} = parse_move(move)
    normalized_game_state = normalize_game_state(game_state)
    moving_value = board_value_at(normalized_game_state, from)
    value_at = board_value_at(normalized_game_state, to)

    if value_at != "x" and value_at == 0 do
      normalized_game_state
      |> put_in([from.row, from.column], 0)
      |> put_in([to.row, to.column], moving_value)
    else
      :error
    end
  end

  def get_column_atom(position) do
    {:ok, coordinate} = parse_coordinate(position)
    coordinate.column
  end

  def get_row_integer(position) do
    {:ok, coordinate} = parse_coordinate(position)
    coordinate.row
  end

  def get_move_to_position_string(move) do
    case split_move(move) do
      {:ok, [_piece, _from_column, _from_row, to_column, to_row]} ->
        "#{to_column}#{to_row}"

      :error ->
        :error
    end
  end

  def get_move_from_position_string(move) do
    case split_move(move) do
      {:ok, [_piece, from_column, from_row, _to_column, _to_row]} ->
        "#{from_column}#{from_row}"

      :error ->
        :error
    end
  end

  def get_board_value_at(game_state, position) do
    {:ok, coordinate} = parse_coordinate(position)
    game_state |> normalize_game_state() |> board_value_at(coordinate)
  end

  defp split_move(move) when is_binary(move) do
    case String.graphemes(move) do
      [_, _, _, _, _] = parts -> {:ok, parts}
      _ -> :error
    end
  end

  defp split_move(_move), do: :error

  defp parse_move(move) do
    with {:ok, [piece, from_column, from_row, to_column, to_row]} <- split_move(move),
         {:ok, from} <- parse_coordinate(from_column <> from_row),
         {:ok, to} <- parse_coordinate(to_column <> to_row) do
      {:ok, piece, from, to}
    end
  end

  defp parse_coordinate(position) when is_binary(position) do
    with [column, row] <- String.graphemes(position),
         {:ok, column_atom, column_index} <- parse_column(column),
         {row_integer, ""} <- Integer.parse(row),
         true <- row_integer in rows() do
      {:ok, %{column: column_atom, column_index: column_index, row: row_integer}}
    else
      _ -> :error
    end
  end

  defp parse_coordinate(_position), do: :error

  defp parse_column(column) do
    column_atom =
      %{"H" => :H, "G" => :G, "F" => :F, "E" => :E, "D" => :D, "C" => :C}
      |> Map.get(String.upcase(column))

    if column_atom, do: {:ok, column_atom, value_map()[column_atom]}, else: :error
  end

  defp board_value_at(game_state, coordinate), do: game_state[coordinate.row][coordinate.column]

  def is_game_finished?(game_state, winning_spot \\ "c3") do
    value_at = get_board_value_at(game_state, winning_spot)

    value_at == "P"
  end

  @doc """
  Rooks can only move left and right in the grid. So they can only traverse if a row or column stays the same.
  Biships can only travers diagonally so they can only travers and equal amount of rows and columns
  Knights can only travers in an L shape 2 and 1. 2 on the row or column then 1 on the opposite direction. So if a knight went 2 on a row then they would need to go 1 in the column directions.
  This is also the same if they went 2 in the column direction they can only go 1 in the  row direction
  Knights is the only piece that can jump so as long as there is a spot available in the direction it can go then it can go there
  all other peices can't go through another piece.
  """
  def is_move_legal?(game_state, move) do
    with {:ok, piece, from, to} <- parse_move(move),
         true <- piece in ["R", "B", "K", "P"],
         false <- from == to,
         normalized_game_state <- normalize_game_state(game_state),
         0 <- board_value_at(normalized_game_state, to) do
      case piece do
        "R" ->
          is_rook_move_legal?(normalized_game_state, from, to)

        "B" ->
          is_bishop_move_legal?(normalized_game_state, from, to)

        knight when knight in ["K", "P"] ->
          is_knight_move_legal?(from, to)
      end
    else
      _ -> false
    end
  end

  @doc false
  defp is_knight_move_legal?(from, to) do
    delta_x = abs(from.column_index - to.column_index)
    delta_y = abs(from.row - to.row)

    cond do
      delta_x == 2 and delta_y == 1 ->
        true

      delta_x == 1 and delta_y == 2 ->
        true

      true ->
        false
    end
  end

  @doc false
  defp is_bishop_move_legal?(game_state, from, to) do
    delta_x = abs(from.column_index - to.column_index)
    delta_y = abs(from.row - to.row)

    delta_x == delta_y and path_clear_diagonal?(game_state, from, to)
  end

  @doc false
  defp is_rook_move_legal?(game_state, from, to) do
    cond do
      from.column == to.column ->
        path_clear_linear?(game_state, from, to)

      to.row == from.row ->
        path_clear_linear?(game_state, from, to)

      true ->
        false
    end
  end

  # Returns true if all intermediate squares between from and to are empty (0) and not blocked ("x")
  defp path_clear_linear?(game_state, from, to) do
    cond do
      from.column == to.column ->
        # moving along column: vary rows by step
        steps = abs(to.row - from.row) - 1

        if steps <= 0 do
          true
        else
          step = if to.row > from.row, do: 1, else: -1

          Enum.all?(1..steps, fn i ->
            board_value_at(game_state, %{from | row: from.row + i * step}) == 0
          end)
        end

      from.row == to.row ->
        # moving along row: vary columns via numeric mapping
        steps = abs(to.column_index - from.column_index) - 1

        if steps <= 0 do
          true
        else
          step = if to.column_index > from.column_index, do: 1, else: -1

          Enum.all?(1..steps, fn i ->
            column_index = from.column_index + i * step
            column = Enum.at(columns(), column_index - 1)
            board_value_at(game_state, %{from | column: column, column_index: column_index}) == 0
          end)
        end

      true ->
        false
    end
  end

  # Returns true if all intermediate diagonal squares are empty
  defp path_clear_diagonal?(game_state, from, to) do
    steps = abs(to.column_index - from.column_index) - 1

    if steps <= 0 do
      true
    else
      step_c = if to.column_index > from.column_index, do: 1, else: -1
      step_r = if to.row > from.row, do: 1, else: -1

      Enum.all?(1..steps, fn s ->
        column_index = from.column_index + s * step_c
        column = Enum.at(columns(), column_index - 1)
        coordinate = %{column: column, column_index: column_index, row: from.row + s * step_r}
        board_value_at(game_state, coordinate) == 0
      end)
    end
  end
end
