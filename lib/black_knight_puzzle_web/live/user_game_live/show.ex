defmodule BlackKnightPuzzleWeb.UserGameLive.Show do
  use BlackKnightPuzzleWeb, :live_view

  alias BlackKnightPuzzle.Game.BlackKnight
  alias BlackKnightPuzzle.Accounts
  alias BlackKnightPuzzle.Games

  def mount(%{"id" => user_game_id}, _session, socket) do
    user_game = Games.get_user_game_by_id(user_game_id)

    current_state = convert_from_json_to_map(user_game.current_state)
    count = Enum.count(user_game.user_game_moves)

    {:ok,
     assign(socket,
       game_map: current_state,
       user_game_id: user_game_id,
       selected_start: nil,
       selected_end: nil,
       move: nil,
       move_count: count || 0,
       error: nil
       # current_user: get_current_user(session)
     )}
  end

  def handle_event("select_position", %{"row" => row, "col" => col, "val" => val}, socket) do
    case {socket.assigns.selected_start, socket.assigns.selected_end} do
      {nil, _} ->
        {:noreply, assign(socket, selected_start: {row, col, val}, move: "#{val}#{row}#{col}")}

      {{start_row, start_col, start_val}, nil} ->
        lower = String.downcase("#{start_col}#{start_row}#{col}#{row}")
        move = "#{start_val}#{lower}"

        case BlackKnight.process_move(socket.assigns.game_map, move) do
          {:ok, "Game finished", new_game_map} ->
            Games.create_user_game_move(%{
              "user_game_id" => socket.assigns.user_game_id,
              "move" => move
            })

            Games.update_user_game(socket.assigns.user_game_id, %{
              "current_state" => new_game_map,
              "won" => true
            })

            socket =
              socket
              |> assign(
                selected_start: nil,
                selected_end: nil,
                move: move,
                move_count: socket.assigns.move_count + 1,
                game_map: new_game_map,
                error: ""
              )
              |> put_flash(:info, "Congratulations! You've won the game!")

            {:noreply, socket}

          {:ok, _, new_game_map} ->
            Games.create_user_game_move(%{
              "user_game_id" => socket.assigns.user_game_id,
              "move" => move
            })

            Games.update_user_game(socket.assigns.user_game_id, %{
              "current_state" => new_game_map,
              "won" => true
            })

            {:noreply,
             assign(socket,
               selected_start: nil,
               selected_end: nil,
               move: move,
               move_count: socket.assigns.move_count + 1,
               game_map: new_game_map,
               error: ""
             )}

          {:error, reason, game_map} ->
            socket =
              socket
              |> assign(
                selected_start: nil,
                selected_end: nil,
                move: nil,
                move_count: socket.assigns.move_count,
                game_map: game_map,
                error: reason
              )
              |> LiveToast.put_toast(:error, "Illegal move.")

            {:noreply, socket}
        end

      _ ->
        {:noreply,
         assign(socket,
           selected_start: nil,
           selected_end: nil,
           move: nil,
           move_count: 0,
           game_map: socket.assigns.game_map
         )}
    end
  end

  defp chess_color(row_index, col_atom, value) do
    col_index = BlackKnight.value_map()[col_atom]

    cond do
      value == "x" ->
        "grey"

      rem(row_index + col_index, 2) == 0 ->
        "white"

      rem(row_index + col_index, 2) != 0 ->
        "black"

      true ->
        "grey"
    end
  end

  # defp get_current_user(session) do
  #   if session["user_token"] == nil do
  #     nil
  #   else
  #     Accounts.get_user_by_session_token(session["user_token"])
  #   end
  # end

  defp image_tag(value) do
    if value != "x" do
      src = "/images/#{value}.png"
      html_content = "<img src=\"#{src}\" alt=\"#{value}\" style=\"width: 100%; height: auto;\">"
      Phoenix.HTML.raw(html_content)
    end
  end

  defp process_move(move, game_map) do
    if BlackKnight.is_move_legal?(game_map, move) do
      updated_game_map = BlackKnight.update_position(game_map, move)
      {:ok, updated_game_map}
    else
      {:error, "Move is not legal"}
    end
  end

  defp convert_from_json_to_map(game_state_json) do
    # Helper function to convert keys of a map to atoms
    convert_keys_to_atoms = fn map ->
      map
      |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
    end

    # Convert each top-level key's nested map
    Enum.reduce(game_state_json, %{}, fn {key, value}, acc ->
      atom_key = String.to_integer(key)
      atom_value = convert_keys_to_atoms.(value)
      Map.put(acc, atom_key, atom_value)
    end)
  end

  # defp convert_from_json_to_map(game_state_json) do
  #   first_map =
  #     game_state_json["1"]
  #     |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
  #
  #   second_map =
  #     game_state_json["2"]
  #     |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
  #
  #   third_map =
  #     game_state_json["3"]
  #     |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
  #
  #   %{
  #     1 => first_map,
  #     2 => second_map,
  #     3 => third_map
  #   }
  # end
end
