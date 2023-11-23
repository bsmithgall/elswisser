defmodule Elswisser.Tournaments.Tournament do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  require IEx
  alias Elswisser.Players.Player

  @types ~w[swiss single_elimination double_elimination]a

  schema "tournaments" do
    field(:name, :string)
    field(:length, :integer)

    field(:type, Ecto.Enum, values: @types)

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
    |> cast(attrs, [:name, :length, :type])
    |> validate_required([:name, :length, :type])
    |> validate_inclusion(:type, @types)
    |> validate_tournament_type_unchaged()
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
    from([round: r, match: m, game: g, white: w, black: b, player: p] in query,
      preload: [
        rounds: {r, matches: {m, games: {g, white: w, black: b}}, games: {g, white: w, black: b}},
        players: p
      ]
    )
  end

  def most_recent_first(query) do
    from(t in query, order_by: [desc: :inserted_at])
  end

  def validate_tournament_type_unchaged(changeset) do
    if !changed?(changeset, :type) or changed?(changeset, :type, from: nil) do
      changeset
    else
      add_error(changeset, :type, "Type cannot be changed after it is set")
    end
  end
end
