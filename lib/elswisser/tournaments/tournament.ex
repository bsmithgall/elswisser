defmodule Elswisser.Tournaments.Tournament do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias Elswisser.Players.Player

  schema "tournaments" do
    field(:name, :string)
    field(:length, :integer)

    many_to_many(:players, Player,
      join_through: Elswisser.Tournaments.TournamentPlayer,
      on_replace: :delete
    )

    has_many(:rounds, Elswisser.Rounds.Round)
    has_many(:games, Elswisser.Games.Game)

    timestamps()
  end

  @doc false
  def changeset(tournament, attrs) do
    tournament
    |> cast(attrs, [:name, :length])
    |> validate_required([:name, :length])
  end

  def from() do
    from(t in Elswisser.Tournaments.Tournament, as: :tournament)
  end
end
