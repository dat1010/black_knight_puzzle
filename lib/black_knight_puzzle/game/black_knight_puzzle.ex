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
      game_state
      |> update_position(move)
      |> check_game_completion(winning_spot)
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

  @pieces ["P", "K", "B", "R"]
  @column_atoms %{"H" => :H, "G" => :G, "F" => :F, "E" => :E, "D" => :D, "C" => :C}
  @row_integers %{"1" => 1, "2" => 2, "3" => 3}

  def value_map() do
    %{H: 1, G: 2, F: 3, E: 4, D: 5, C: 6}
  end

  @doc """
  Builds a move string such as "Rc2c3" from client-supplied event params.

  Returns `:error` unless every part is a string; the result still has to pass
  `parse_move/1`, which checks that the squares are on the board.
  """
  def build_move(from_row, from_col, piece, to_row, to_col)
      when is_binary(from_row) and is_binary(from_col) and is_binary(piece) and
             is_binary(to_row) and is_binary(to_col) do
    piece <> String.downcase(from_col <> from_row <> to_col <> to_row)
  end

  def build_move(_from_row, _from_col, _piece, _to_row, _to_col), do: :error

  @doc """
  Parses a move string such as "Rc2c3" into `{:ok, piece, from, to}`.

  Returns `:error` for anything that isn't a known piece followed by two squares
  on the board. Squares are returned lowercase, e.g. "c2".
  """
  def parse_move(<<piece::binary-size(1), from::binary-size(2), to::binary-size(2)>>)
      when piece in @pieces do
    from = String.downcase(from)
    to = String.downcase(to)

    if valid_square?(from) and valid_square?(to) do
      {:ok, piece, from, to}
    else
      :error
    end
  end

  def parse_move(_move), do: :error

  defp valid_square?(<<col::binary-size(1), row::binary-size(1)>>) do
    Map.has_key?(@column_atoms, String.upcase(col)) and Map.has_key?(@row_integers, row)
  end

  defp valid_square?(_square), do: false

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
          row when is_binary(row) -> Map.fetch!(@row_integers, row)
        end

      normalized_cols =
        Map.new(cols, fn {col, value} ->
          normalized_col =
            case col do
              col when is_atom(col) -> col
              col when is_binary(col) -> Map.fetch!(@column_atoms, col)
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
    # get move_to_position
    position_to_string = get_move_to_position_string(move)
    move_from_string = get_move_from_position_string(move)

    moving_value = get_board_value_at(game_state, move_from_string)
    value_at = get_board_value_at(game_state, position_to_string)

    if value_at != "x" and value_at == 0 do
      # check if move is valid
      column_atom = get_column_atom(position_to_string)
      row_integer = get_row_integer(position_to_string)

      from_column_atom = get_column_atom(move_from_string)
      from_row_integer = get_row_integer(move_from_string)

      game_state
      |> put_in([from_row_integer, from_column_atom], 0)
      |> put_in([row_integer, column_atom], moving_value)
    else
      :error
    end
  end

  def get_column_atom(position) do
    position_array = String.split(position, "", trim: true)

    [column_lower_case | _row_array] = position_array

    Map.fetch!(@column_atoms, String.upcase(column_lower_case))
  end

  def get_row_integer(position) do
    position_array = String.split(position, "", trim: true)

    [_column_lower_case | row_array] = position_array

    Map.fetch!(@row_integers, hd(row_array))
  end

  def get_move_to_position_string(move) do
    position_array = String.split(move, "", trim: true)

    if length(position_array) == 5 do
      column = Enum.at(position_array, 3)
      row = Enum.at(position_array, 4)
      "#{column}#{row}"
    else
      :error
    end
  end

  def get_move_from_position_string(move) do
    position_array = String.split(move, "", trim: true)

    if length(position_array) == 5 do
      column = Enum.at(position_array, 1)
      row = Enum.at(position_array, 2)
      "#{column}#{row}"
    else
      :error
    end
  end

  def get_board_value_at(game_state, position) do
    game_state = normalize_game_state(game_state)

    game_state[get_row_integer(position)][get_column_atom(position)]
  end

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
    # The piece is read from the board, never trusted from the move string. A move
    # whose piece letter doesn't match the board (e.g. a rook sent as "K") is rejected.
    with {:ok, piece, position_from, position_to} <- parse_move(move),
         true <- position_from != position_to,
         ^piece <- get_board_value_at(game_state, position_from),
         0 <- get_board_value_at(game_state, position_to) do
      case piece do
        "R" -> is_rook_move_legal?(game_state, position_from, position_to)
        "B" -> is_bishop_move_legal?(game_state, position_from, position_to)
        "K" -> is_knight_move_legal?(position_from, position_to)
        "P" -> is_knight_move_legal?(position_from, position_to)
      end
    else
      _ -> false
    end
  end

  @doc false
  defp is_knight_move_legal?(position_from, position_to) do
    from_column_atom = get_column_atom(position_from)
    from_row_integer = get_row_integer(position_from)

    to_column_atom = get_column_atom(position_to)
    to_row_integer = get_row_integer(position_to)

    from_column_integer = value_map()[from_column_atom]
    to_column_integer = value_map()[to_column_atom]

    delta_x = abs(from_column_integer - to_column_integer)
    delta_y = abs(from_row_integer - to_row_integer)

    cond do
      delta_x == 2 and delta_y == 1 ->
        true

      delta_x == 1 and delta_y == 2 ->
        true

      delta_y == 2 and delta_x == 1 ->
        true

      delta_y == 1 and delta_x == 2 ->
        true

      true ->
        false
    end
  end

  @doc false
  defp is_bishop_move_legal?(game_state, position_from, position_to) do
    from_column_atom = get_column_atom(position_from)
    from_row_integer = get_row_integer(position_from)

    to_column_atom = get_column_atom(position_to)
    to_row_integer = get_row_integer(position_to)

    from_column_integer = value_map()[from_column_atom]
    to_column_integer = value_map()[to_column_atom]

    delta_x = abs(from_column_integer - to_column_integer)
    delta_y = abs(from_row_integer - to_row_integer)

    delta_x == delta_y and path_clear_diagonal?(game_state, position_from, position_to)
  end

  @doc false
  defp is_rook_move_legal?(game_state, position_from, position_to) do
    from_column_atom = get_column_atom(position_from)
    from_row_integer = get_row_integer(position_from)

    to_column_atom = get_column_atom(position_to)
    to_row_integer = get_row_integer(position_to)

    cond do
      from_column_atom == to_column_atom ->
        path_clear_linear?(game_state, position_from, position_to)

      to_row_integer == from_row_integer ->
        path_clear_linear?(game_state, position_from, position_to)

      true ->
        false
    end
  end

  # Returns true if all intermediate squares between from and to are empty (0) and not blocked ("x")
  defp path_clear_linear?(game_state, position_from, position_to) do
    from_col = get_column_atom(position_from)
    from_row = get_row_integer(position_from)
    to_col = get_column_atom(position_to)
    to_row = get_row_integer(position_to)

    cols = value_map()

    cond do
      from_col == to_col ->
        # moving along column: vary rows by step
        steps = abs(to_row - from_row) - 1

        if steps <= 0 do
          true
        else
          step = if to_row > from_row, do: 1, else: -1

          Enum.all?(1..steps, fn i ->
            r = from_row + i * step
            pos = "#{Atom.to_string(from_col) |> String.downcase()}#{r}"
            get_board_value_at(game_state, pos) == 0
          end)
        end

      from_row == to_row ->
        # moving along row: vary columns via numeric mapping
        from_c_i = cols[from_col]
        to_c_i = cols[to_col]
        steps = abs(to_c_i - from_c_i) - 1

        if steps <= 0 do
          true
        else
          step = if to_c_i > from_c_i, do: 1, else: -1

          Enum.all?(1..steps, fn i ->
            ci = from_c_i + i * step
            col_atom = Enum.find(cols, fn {_k, v} -> v == ci end) |> elem(0)
            pos = "#{Atom.to_string(col_atom) |> String.downcase()}#{from_row}"
            get_board_value_at(game_state, pos) == 0
          end)
        end

      true ->
        false
    end
  end

  # Returns true if all intermediate diagonal squares are empty
  defp path_clear_diagonal?(game_state, position_from, position_to) do
    from_col = get_column_atom(position_from)
    from_row = get_row_integer(position_from)
    to_col = get_column_atom(position_to)
    to_row = get_row_integer(position_to)

    cols = value_map()
    from_c_i = cols[from_col]
    to_c_i = cols[to_col]

    steps = abs(to_c_i - from_c_i) - 1

    if steps <= 0 do
      true
    else
      step_c = if to_c_i > from_c_i, do: 1, else: -1
      step_r = if to_row > from_row, do: 1, else: -1

      Enum.all?(1..steps, fn s ->
        ci = from_c_i + s * step_c
        ri = from_row + s * step_r
        col_atom = Enum.find(cols, fn {_k, v} -> v == ci end) |> elem(0)
        pos = "#{Atom.to_string(col_atom) |> String.downcase()}#{ri}"
        get_board_value_at(game_state, pos) == 0
      end)
    end
  end
end
