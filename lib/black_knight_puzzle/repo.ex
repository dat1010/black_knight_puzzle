defmodule BlackKnightPuzzle.Repo do
  use Ecto.Repo,
    otp_app: :black_knight,
    adapter: Ecto.Adapters.Postgres
end
