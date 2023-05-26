defmodule Elswisser.Players.Player do
  use Ecto.Schema
  import Ecto.Changeset

  schema "players" do
    field(:name, :string)
    field(:rating, :integer)

    has_many(:white_games, Elswisser.Games.Game, foreign_key: :white_id)
    has_many(:black_games, Elswisser.Games.Game, foreign_key: :black_id)

    timestamps()
  end

  @doc false
  def changeset(player, attrs) do
    player
    |> cast(attrs, [:name, :rating])
    |> validate_required([:name, :rating])
  end
end
