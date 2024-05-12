defmodule BlackKnightPuzzle.Repo do
  use Ecto.Repo,
    otp_app: :black_knight_puzzle,
    adapter: Ecto.Adapters.Postgres
end
