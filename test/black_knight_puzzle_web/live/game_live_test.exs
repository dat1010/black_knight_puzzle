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

  test "new game sends logged-out users to log in", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    assert {:error, {:live_redirect, %{to: "/users/log_in"}}} = render_click(view, "new_game")
  end

  test "new game starts a saved game for logged-in users", %{conn: conn} do
    %{conn: conn, user: user} = register_and_log_in_user(%{conn: conn})
    {:ok, view, _html} = live(conn, ~p"/")

    assert {:error, {:live_redirect, %{to: "/games/" <> id}}} = render_click(view, "new_game")
    assert BlackKnightPuzzle.Games.get_user_game!(user, id)
  end
end
