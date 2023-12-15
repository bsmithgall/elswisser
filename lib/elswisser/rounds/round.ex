defmodule Elswisser.Rounds.Round do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias Elswisser.Tournaments.Tournament
  alias Elswisser.Matches.Match

  schema "rounds" do
    field(:number, :integer)
    field(:status, Ecto.Enum, values: [:pairing, :playing, :complete])

    belongs_to(:tournament, Tournament)
    has_many(:matches, Match)
    has_many(:games, through: [:matches, :games])

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
    from([round: r] in query, where: r.id == ^id)
  end

  def where_tournament_id(query, id) do
    from([round: r] in query, where: r.tournament_id == ^id)
  end

  def where_round_number(query, number) do
    from([round: r] in query, where: r.number == ^number)
  end

  def with_matches(query) do
    from([round: r] in query, left_join: m in assoc(r, :matches), as: :match)
  end

  def with_games(query) do
    from([round: r] in query, left_join: g in assoc(r, :games), as: :game)
  end

  def preload_games_and_players(query) do
    from([game: g, white: w, black: b] in query, preload: [games: {g, white: w, black: b}])
  end

  def preload_games(query) do
    from([game: g] in query, preload: [games: g])
  end

  def preload_matches(query) do
    from([match: m] in query, preload: [matches: m])
  end

  def preload_matches_with_games(query) do
    from([match: m, game: g] in query,
      preload: [
        matches: {m, games: g},
        games: g
      ]
    )
  end

  def preload_all(query) do
    from([match: m, game: g, white: w, black: b] in query,
      preload: [
        matches: {m, games: {g, white: w, black: b}},
        games: {g, white: w, black: b}
      ]
    )
  end

  def order_by_number(query) do
    from([round: r] in query, order_by: [asc: r.number])
  end
end
