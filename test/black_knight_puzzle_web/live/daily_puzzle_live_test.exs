defmodule BlackKnightPuzzleWeb.DailyPuzzleLiveTest do
  use BlackKnightPuzzleWeb.ConnCase

  import Phoenix.LiveViewTest

  test "logged out users can load the daily puzzle", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/daily")

    assert html =~ "Daily Black Knight"
    assert html =~ "Moves"
    assert html =~ "Goal"
  end

  test "logged in users can load the daily puzzle", %{conn: conn} do
    %{conn: conn} = register_and_log_in_user(%{conn: conn})

    {:ok, _view, html} = live(conn, ~p"/daily")

    assert html =~ "Daily Black Knight"
  end
end
