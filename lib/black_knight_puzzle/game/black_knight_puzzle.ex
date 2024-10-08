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
  def process_move(game_state, move) do
    cond do
      !is_move_legal?(game_state, move) ->
        {:error, "Illegal move", game_state}

      is_move_legal?(game_state, move) ->
        updated_game_state = update_position(game_state, move)
        check_game_completion(updated_game_state)

      true ->
        {:error, "Unexpected error", game_state}
    end
  end

  defp check_game_completion(game_state) do
    if is_game_finished?(game_state) do
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

    column_lower_case
    |> String.upcase()
    |> String.to_atom()
  end

  def get_row_integer(position) do
    position_array = String.split(position, "", trim: true)

    [_column_lower_case | row_array] = position_array

    row_array
    |> hd()
    |> String.to_integer()
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
    # TODO need to make sure the postion we get is valid first
    position_array = String.split(position, "", trim: true)

    [column_lower_case | row_array] = position_array

    formatted_column =
      column_lower_case
      |> String.upcase()
      |> String.to_atom()

    formatted_row =
      row_array
      |> hd()
      |> String.to_integer()

    game_state[formatted_row][formatted_column]
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
    piece =
      move
      |> String.split("", trim: true)
      |> hd()

    position_from = get_move_from_position_string(move)
    position_to = get_move_to_position_string(move)
    value_at = get_board_value_at(game_state, position_to)

    if position_to != position_from and value_at == 0 do
      case piece do
        "R" ->
          is_rook_move_legal?(position_from, position_to)

        "B" ->
          is_bishop_move_legal?(position_from, position_to)

        "K" ->
          is_knight_move_legal?(position_from, position_to)

        "P" ->
          is_knight_move_legal?(position_from, position_to)

        _ ->
          false
      end
    else
      false
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
  defp is_bishop_move_legal?(position_from, position_to) do
    from_column_atom = get_column_atom(position_from)
    from_row_integer = get_row_integer(position_from)

    to_column_atom = get_column_atom(position_to)
    to_row_integer = get_row_integer(position_to)

    from_column_integer = value_map()[from_column_atom]
    to_column_integer = value_map()[to_column_atom]

    delta_x = abs(from_column_integer - to_column_integer)
    delta_y = abs(from_row_integer - to_row_integer)

    delta_x == delta_y
  end

  @doc false
  defp is_rook_move_legal?(position_from, position_to) do
    from_column_atom = get_column_atom(position_from)
    from_row_integer = get_row_integer(position_from)

    to_column_atom = get_column_atom(position_to)
    to_row_integer = get_row_integer(position_to)

    cond do
      from_column_atom == to_column_atom ->
        true

      to_row_integer == from_row_integer ->
        true

      true ->
        false
    end
  end
end
