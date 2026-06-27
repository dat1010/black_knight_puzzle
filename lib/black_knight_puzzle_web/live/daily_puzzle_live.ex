defmodule BlackKnightPuzzleWeb.DailyPuzzleLive do
  use BlackKnightPuzzleWeb, :live_view

  alias BlackKnightPuzzle.Accounts
  alias BlackKnightPuzzle.Game.BlackKnight
  alias BlackKnightPuzzle.Games

  @impl true
  def mount(_params, session, socket) do
    daily_puzzle = Games.get_or_create_daily_puzzle(Date.utc_today())
    current_user = get_current_user(session)
    saved_score = get_saved_score(current_user, daily_puzzle)

    {:ok,
     assign(socket,
       daily_puzzle: daily_puzzle,
       game_map: BlackKnight.normalize_game_state(daily_puzzle.start_state),
       goal_position: daily_puzzle.goal_position,
       selected_start: nil,
       selected_end: nil,
       move: nil,
       move_count: 0,
       current_user: current_user,
       saved_score: saved_score,
       won: false,
       score_saved?: false,
       error: nil
     )}
  end

  @impl true
  def handle_event("select_position", %{"row" => row, "col" => col, "val" => val}, socket) do
    case {socket.assigns.selected_start, socket.assigns.selected_end} do
      {nil, _} ->
        {:noreply, assign(socket, selected_start: {row, col, val}, move: "#{val}#{row}#{col}")}

      {{start_row, start_col, start_val}, nil} ->
        move = build_move(start_row, start_col, start_val, row, col)
        process_completed_move(socket, move)

      _ ->
        {:noreply, clear_selection(socket)}
    end
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
    move = build_move(start_row, start_col, start_val, row, col)
    process_completed_move(socket, move)
  end

  defp process_completed_move(%{assigns: %{won: true}} = socket, _move), do: {:noreply, socket}

  defp process_completed_move(socket, move) do
    case BlackKnight.process_move(socket.assigns.game_map, move, socket.assigns.goal_position) do
      {:ok, "Game finished", new_game_map} ->
        move_count = socket.assigns.move_count + 1
        {_result, saved_score} = save_score(socket, move_count)

        socket =
          socket
          |> assign(
            selected_start: nil,
            selected_end: nil,
            move: move,
            move_count: move_count,
            game_map: new_game_map,
            won: true,
            saved_score: saved_score || socket.assigns.saved_score,
            score_saved?: not is_nil(saved_score),
            error: ""
          )
          |> put_flash(:info, "Daily puzzle solved!")

        {:noreply, socket}

      {:ok, _, new_game_map} ->
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
            game_map: game_map,
            error: reason
          )
          |> LiveToast.put_toast(:error, "Illegal move.")

        {:noreply, socket}
    end
  end

  defp save_score(%{assigns: %{current_user: nil}}, _move_count), do: {{:ok, nil}, nil}

  defp save_score(socket, move_count) do
    result =
      Games.save_daily_score(
        socket.assigns.current_user,
        socket.assigns.daily_puzzle,
        move_count
      )

    case result do
      {:ok, score} -> {result, score}
      {:error, _changeset} -> {result, nil}
    end
  end

  defp clear_selection(socket) do
    assign(socket,
      selected_start: nil,
      selected_end: nil,
      move: nil,
      game_map: socket.assigns.game_map
    )
  end

  defp build_move(start_row, start_col, start_val, row, col) do
    lower = String.downcase("#{start_col}#{start_row}#{col}#{row}")
    "#{start_val}#{lower}"
  end

  defp get_current_user(session) do
    if session["user_token"] == nil do
      nil
    else
      Accounts.get_user_by_session_token(session["user_token"])
    end
  end

  defp get_saved_score(nil, _daily_puzzle), do: nil

  defp get_saved_score(current_user, daily_puzzle) do
    Games.get_daily_score(current_user.id, daily_puzzle.id)
  end

  defp image_tag(value) do
    if value != "x" do
      src = "/images/#{value}.png"
      html_content = "<img src=\"#{src}\" alt=\"#{value}\" style=\"width: 100%; height: auto;\">"
      Phoenix.HTML.raw(html_content)
    end
  end
end
