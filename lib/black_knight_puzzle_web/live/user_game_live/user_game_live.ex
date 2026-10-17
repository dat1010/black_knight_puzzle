defmodule BlackKnightPuzzleWeb.UserGameLive do
  use BlackKnightPuzzleWeb, :live_view

  alias BlackKnightPuzzle.Games

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, user_games: Games.list_user_games(socket.assigns.current_user))}
  end
end
