defmodule BlackKnightPuzzleWeb.UserGameLive.Show do
  use BlackKnightPuzzleWeb, :live_view

  alias BlackKnightPuzzle.Game.BlackKnight
  alias BlackKnightPuzzle.Games

  @impl true
  def mount(%{"id" => user_game_id}, _session, socket) do
    user_game = Games.get_user_game!(socket.assigns.current_user, user_game_id)

    {:ok,
     assign(socket,
       user_game: user_game,
       game_map: BlackKnight.normalize_game_state(user_game.current_state),
       selected_start: nil,
       selected_end: nil,
       move: nil,
       move_count: length(user_game.user_game_moves),
       error: nil
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

  defp process_completed_move(%{assigns: %{user_game: %{won: true}}} = socket, _move) do
    {:noreply, socket}
  end

  defp process_completed_move(socket, move) do
    case BlackKnight.process_move(socket.assigns.game_map, move) do
      {:ok, message, new_game_map} ->
        won? = message == "Game finished"

        {:ok, user_game} =
          Games.record_user_game_move(socket.assigns.user_game, move, new_game_map, won?)

        socket =
          assign(socket,
            user_game: user_game,
            selected_start: nil,
            selected_end: nil,
            move: move,
            move_count: socket.assigns.move_count + 1,
            game_map: new_game_map,
            error: ""
          )

        socket =
          if won?,
            do: put_flash(socket, :info, "Congratulations! You've won the game!"),
            else: socket

        {:noreply, socket}

      {:error, _reason, _game_map} ->
        {:noreply, reject_move(socket)}
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

  defp image_tag(value) do
    if value != "x" do
      src = "/images/#{value}.png"
      html_content = "<img src=\"#{src}\" alt=\"#{value}\" style=\"width: 100%; height: auto;\">"
      Phoenix.HTML.raw(html_content)
    end
  end
end
