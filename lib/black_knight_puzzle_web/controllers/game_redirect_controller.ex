defmodule BlackKnightPuzzleWeb.GameRedirectController do
  use BlackKnightPuzzleWeb, :controller

  def index(conn, _params), do: redirect(conn, to: ~p"/games")

  def show(conn, %{"id" => id}), do: redirect(conn, to: ~p"/games/#{id}")
end
