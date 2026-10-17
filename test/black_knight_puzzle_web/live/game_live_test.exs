defmodule BlackKnightPuzzleWeb.GameLiveTest do
  use BlackKnightPuzzleWeb.ConnCase

  import Phoenix.LiveViewTest

  test "a legal move is counted", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    html =
      render_hook(view, "move_piece", %{
        "from_row" => "2",
        "from_col" => "C",
        "val" => "R",
        "to_row" => "3",
        "to_col" => "C"
      })

    assert html =~ "Count: 1"
  end

  test "malformed move events don't crash the page", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    assert render_hook(view, "move_piece", %{"from_row" => "x"}) =~ "Count: 0"
    assert Process.alive?(view.pid)
  end
end
