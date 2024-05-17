defmodule BlackKnightPuzzleWeb.GameLive do
  use BlackKnightPuzzleWeb, :live_view

  alias BlackKnightPuzzle.Game.BlackKnight
  alias BlackKnightPuzzle.Accounts
  alias BlackKnightPuzzle.Games

  @impl true
  def mount(_params, session, socket) do
    {:ok,
     assign(socket,
       game_map: initial_game_state(),
       selected_start: nil,
       selected_end: nil,
       move: nil,
       error: nil,
       current_user: get_current_user(session)
     )}
  end

  defp initial_game_state do
    BlackKnight.set_board()
  end

  @impl true
  def handle_event("submit_move", %{"move" => move}, socket) do
    case process_move(move, socket.assigns.game_map) do
      {:ok, new_game_map} ->
        {:noreply,
         socket
         |> assign(game_map: new_game_map)}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(error: nil)
         |> put_flash(:error, "Failed to submit move: #{reason}")}
    end
  end

  # def handle_event("submit_move", %{"move" => move}, socket) do
  #
  #   case process_move(move, socket.assigns.game_map) do
  #     {:ok, new_game_map} ->
  #       {:noreply, assign(socket, game_map: new_game_map)}
  #
  #     {:error, reason} ->
  #       {:noreply, assign(socket, error: reason)}
  #   end
  # end

  def handle_event("select_position", %{"row" => row, "col" => col, "val" => val}, socket) do
    case {socket.assigns.selected_start, socket.assigns.selected_end} do
      {nil, _} ->
        {:noreply, assign(socket, selected_start: {row, col, val}, move: "#{val}#{row}#{col}")}

      {{start_row, start_col, start_val}, nil} ->
        lower = String.downcase("#{start_col}#{start_row}#{col}#{row}")
        move = "#{start_val}#{lower}"

        case process_move(move, socket.assigns.game_map) do
          {:ok, new_game_map} ->
            {:noreply,
             assign(socket,
               selected_start: nil,
               selected_end: nil,
               move: move,
               game_map: new_game_map,
               error: ""
             )}

          {:error, reason} ->
            {:noreply,
             assign(socket,
               selected_start: nil,
               selected_end: nil,
               move: nil,
               game_map: socket.assigns.game_map,
               error: reason
             )}
        end

      _ ->
        {:noreply,
         assign(socket,
           selected_start: nil,
           selected_end: nil,
           move: nil,
           game_map: socket.assigns.game_map
         )}
    end
  end

  @impl true
  def handle_event("new_game", _, socket) do
    user_id = socket.assigns.current_user.id

    {:ok, user_game} =
      %{
        "user_id" => user_id,
        "game_id" => 1,
        "current_state" => initial_game_state()
      }
      |> Games.create_user_game()

    {:noreply, push_redirect(socket, to: "/users/#{user_id}/games/#{user_game.id}")}
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

  defp get_current_user(session) do
    if session["user_token"] == nil do
      nil
    else
      Accounts.get_user_by_session_token(session["user_token"])
    end
  end

  defp image_tag(value) do
    if value != "x" do
      src = "images/#{value}.png"
      html_content = "<img src=\"#{src}\" alt=\"#{value}\" style=\"width: 100%; height: auto;\">"
      testing = Phoenix.HTML.raw(html_content)
      dbg()
      testing
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
end
