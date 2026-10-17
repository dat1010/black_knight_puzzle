defmodule BlackKnightPuzzleWeb.UserGameLiveTest do
  use BlackKnightPuzzleWeb.ConnCase

  import Phoenix.LiveViewTest
  import BlackKnightPuzzle.AccountsFixtures

  alias BlackKnightPuzzle.Games

  @rook_c2_to_c3 %{
    "from_row" => "2",
    "from_col" => "C",
    "val" => "R",
    "to_row" => "3",
    "to_col" => "C"
  }

  setup :register_and_log_in_user

  test "the game list shows only the user's games", %{conn: conn, user: user} do
    {:ok, mine} = Games.start_user_game(user)
    {:ok, theirs} = Games.start_user_game(user_fixture())

    {:ok, _view, html} = live(conn, ~p"/games")

    assert html =~ ~s(id="game-#{mine.id}")
    refute html =~ ~s(id="game-#{theirs.id}")
  end

  test "another user's game is a 404", %{conn: conn} do
    {:ok, theirs} = Games.start_user_game(user_fixture())

    assert_error_sent 404, fn -> get(conn, ~p"/games/#{theirs.id}") end
  end

  test "a normal move is saved and does not win the game", %{conn: conn, user: user} do
    {:ok, user_game} = Games.start_user_game(user)
    {:ok, view, _html} = live(conn, ~p"/games/#{user_game.id}")

    assert render_hook(view, "move_piece", @rook_c2_to_c3) =~ "Count: 1"

    user_game = Games.get_user_game!(user, user_game.id)
    refute user_game.won
    assert [%{move: "Rc2c3"}] = user_game.user_game_moves
  end

  test "a won game accepts no more moves", %{conn: conn, user: user} do
    {:ok, user_game} = Games.start_user_game(user)
    {:ok, _} = Games.record_user_game_move(user_game, "Pe2c3", user_game.current_state, true)

    {:ok, view, _html} = live(conn, ~p"/games/#{user_game.id}")
    render_hook(view, "move_piece", @rook_c2_to_c3)

    assert [_winning_move] = Games.get_user_game!(user, user_game.id).user_game_moves
  end

  test "old game URLs redirect to the new ones", %{conn: conn, user: user} do
    {:ok, user_game} = Games.start_user_game(user)

    assert redirected_to(get(conn, "/users/#{user.id}/games")) == ~p"/games"

    assert redirected_to(get(conn, "/users/#{user.id}/games/#{user_game.id}")) ==
             ~p"/games/#{user_game.id}"
  end
end
