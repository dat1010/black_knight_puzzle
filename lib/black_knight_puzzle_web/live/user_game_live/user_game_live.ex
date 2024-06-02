defmodule BlackKnightPuzzleWeb.UserGameLive do
  use BlackKnightPuzzleWeb, :live_view

  alias BlackKnightPuzzle.Games

  @impl true
  def mount(%{"id" => id}, _, socket) do
    # games = Games.list_games_for_user(user_id)
    user_games = Games.list_user_games_by_user_id(id)

    {:ok, assign(socket, user_games: user_games, user_id: id)}
  end
end
