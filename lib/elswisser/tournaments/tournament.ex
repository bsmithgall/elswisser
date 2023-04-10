defmodule Elswisser.Tournaments.Tournament do
  use Ecto.Schema
  import Ecto.Changeset

  alias Elswisser.Players.Player

  schema "tournaments" do
    field :name, :string
    field :length, :integer

    many_to_many :players, Player, join_through: "tournament_players", on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(tournament, attrs) do
    tournament
    |> cast(attrs, [:name, :length])
    |> validate_required([:name, :length])
  end
end
