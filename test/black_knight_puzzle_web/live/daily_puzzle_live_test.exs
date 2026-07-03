defmodule BlackKnightPuzzleWeb.DailyPuzzleLiveTest do
  use BlackKnightPuzzleWeb.ConnCase

  import Phoenix.LiveViewTest
  alias BlackKnightPuzzle.Games

  test "logged out users can load the daily puzzle", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/daily")

    assert html =~ "Move:"
    assert html =~ "Count:"
    assert html =~ "Goal:"
  end

  test "legal moves increment the move count", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/daily")
    assert html =~ "Count: 0"

    daily_puzzle = Games.get_or_create_daily_puzzle(Date.utc_today())
    first_move = hd(daily_puzzle.solution_moves)

    html =
      view
      |> render_hook("move_piece", move_piece_params(first_move))

    assert html =~ "Count: 1"
  end

  test "logged in users can load the daily puzzle", %{conn: conn} do
    %{conn: conn} = register_and_log_in_user(%{conn: conn})

    {:ok, _view, html} = live(conn, ~p"/daily")

    assert html =~ "Move:"
  end

  defp move_piece_params(<<piece, from_col, from_row, to_col, to_row>>) do
    %{
      "from_row" => <<from_row>>,
      "from_col" => String.upcase(<<from_col>>),
      "val" => <<piece>>,
      "to_row" => <<to_row>>,
      "to_col" => String.upcase(<<to_col>>)
    }
  end
end
