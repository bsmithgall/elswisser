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

  def where_id(query, id) do
    from([tournament: t] in query, where: t.id == ^id)
  end

  def with_rounds(query) do
    from([tournament: t] in query,
      left_join: r in assoc(t, :rounds),
      as: :round
    )
  end

  def with_players(query) do
    from([tournament: t] in query,
      left_join: p in assoc(t, :players),
      as: :player
    )
  end

  def preload_rounds(query) do
    from([round: r] in query, preload: [rounds: r])
  end

  def preload_players(query) do
    from([player: p] in query, preload: [players: p])
  end

  def preload_rounds_and_games(query) do
    from([round: r, game: g] in query, preload: [rounds: {r, games: g}])
  end

  def preload_all(query) do
    from([round: r, game: g, white: w, black: b, player: p] in query,
      preload: [rounds: {r, games: {g, white: w, black: b}}, players: p]
    )
  end

  def most_recent_first(query) do
    from(t in query, order_by: [desc: :inserted_at])
  end
end
