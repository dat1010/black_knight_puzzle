defmodule BlackKnightPuzzle.Games.Game do
  use Ecto.Schema
  import Ecto.Changeset

  schema "games" do
    field :name, :string
    field :start_state, :map
    timestamps()
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:name, :start_state])
    |> validate_required([:name, :start_state])
  end
end
