defmodule BlackKnightPuzzleWeb.UserGameLive.Show do
  use BlackKnightPuzzleWeb, :live_view

  alias BlackKnightPuzzle.Game.BlackKnight
  alias BlackKnightPuzzle.Games

  @impl true
  def mount(%{"id" => user_game_id}, _session, socket) do
    user_game = Games.get_user_game_by_id(user_game_id)

    current_state = BlackKnight.normalize_game_state(user_game.current_state)
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

  @impl true
  def handle_event(
        "move_piece",
        %{
          "from_row" => start_row,
          "from_col" => start_col,
          "val" => start_val,
          "to_row" => row,
          "to_col" => col
        },
        socket
      ) do
    case BlackKnight.build_move(start_row, start_col, start_val, row, col) do
      :error -> {:noreply, reject_move(socket)}
      move -> process_completed_move(socket, move)
    end
  end

  def handle_event("move_piece", _params, socket) do
    {:noreply, reject_move(socket)}
  end

  defp process_completed_move(socket, move) do
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
  end

  defp reject_move(socket) do
    socket
    |> assign(selected_start: nil, selected_end: nil, move: nil, error: "Illegal move")
    |> LiveToast.put_toast(:error, "Illegal move.")
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
end
