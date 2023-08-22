defmodule Elswisser.Rounds.Round do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias Elswisser.Games.Game

  schema "rounds" do
    field(:number, :integer)
    field(:expected_games, :integer, virtual: true)
    field(:status, Ecto.Enum, values: [:pairing, :playing, :complete])

    belongs_to(:tournament, Elswisser.Tournaments.Tournament)
    has_many(:games, Game)

    timestamps()
  end

  @doc false
  def changeset(round, attrs) do
    round
    |> cast(attrs, [:number, :tournament_id, :status])
    |> validate_required([:number, :tournament_id, :status])
  end

  def from() do
    from(r in Elswisser.Rounds.Round, as: :round)
  end

  def where_id(query, id) do
    from(r in query, where: r.id == ^id)
  end

  def with_games(query) do
    from(r in query, left_join: g in assoc(r, :games), as: :game)
  end

  def preload_games_and_players(query) do
    from([game: g, white: w, black: b] in query, preload: [games: {g, white: w, black: b}])
  end

  def preload_games(query) do
    from([game: g] in query, preload: [games: g])
  end
end
