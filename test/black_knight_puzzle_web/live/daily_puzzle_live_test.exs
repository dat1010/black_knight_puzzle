defmodule BlackKnightPuzzleWeb.DailyPuzzleLiveTest do
  use BlackKnightPuzzleWeb.ConnCase

  import Phoenix.LiveViewTest
  import BlackKnightPuzzle.GamesFixtures

  setup do
    %{daily_puzzle: daily_puzzle_fixture(Date.utc_today())}
  end

  test "logged out users can load the daily puzzle", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/daily")

    assert html =~ "Move:"
    assert html =~ "Count:"
    assert html =~ "Goal:"
  end

  test "legal moves increment the move count", %{conn: conn, daily_puzzle: daily_puzzle} do
    {:ok, view, html} = live(conn, ~p"/daily")
    assert html =~ "Count: 0"

    first_move = hd(daily_puzzle.solution_moves)

    html =
      view
      |> render_hook("move_piece", move_piece_params(first_move))

    assert html =~ "Count: 1"
  end

  test "a forged piece type is rejected and not counted", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/daily")

    # d1 holds a bishop; claiming it is a knight must not let it jump to c3.
    html =
      render_hook(view, "move_piece", %{
        "from_row" => "1",
        "from_col" => "D",
        "val" => "K",
        "to_row" => "3",
        "to_col" => "C"
      })

    assert html =~ "Count: 0"
    assert html =~ ~s(data-row="1" data-col="D" data-val="B")
    assert html =~ ~s(data-row="3" data-col="C" data-val="0")
  end

  test "malformed move events don't crash the page", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/daily")

    for params <- [
          %{},
          %{"from_row" => "9", "from_col" => "Z", "val" => "R", "to_row" => "3", "to_col" => "C"},
          %{"from_row" => 2, "from_col" => "C", "val" => "R", "to_row" => "3", "to_col" => "C"},
          %{"from_row" => "2", "from_col" => %{}, "val" => "R", "to_row" => "3", "to_col" => "C"}
        ] do
      assert render_hook(view, "move_piece", params) =~ "Count: 0"
    end

    assert Process.alive?(view.pid)
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
