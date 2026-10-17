defmodule BlackKnightPuzzleWeb.PageControllerTest do
  use BlackKnightPuzzleWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ ~s(id="chess-board")
  end
end
