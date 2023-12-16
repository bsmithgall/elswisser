defmodule Elswisser.Rounds.Round do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias Elswisser.Tournaments.Tournament
  alias Elswisser.Matches.Match

  @statuses ~w[pairing playing complete]a
  @types ~w[winner loser championship none]a

  schema "rounds" do
    field(:number, :integer)
    field(:status, Ecto.Enum, values: @statuses)
    field(:type, Ecto.Enum, values: @types, default: :none)
    field(:display_name, :string)

    belongs_to(:tournament, Tournament)
    has_many(:matches, Match)
    has_many(:games, through: [:matches, :games])

    timestamps()
  end

  @doc false
  def changeset(round, attrs) do
    round
    |> cast(attrs, [:number, :tournament_id, :status, :type, :display_name])
    |> add_display_name_if_missing()
    |> validate_required([:number, :tournament_id, :status, :display_name])
  end

  def add_display_name_if_missing(%Ecto.Changeset{changes: %{display_name: _}} = cs), do: cs

  def add_display_name_if_missing(%Ecto.Changeset{data: %__MODULE__{display_name: nil}} = cs) do
    cs |> put_change(:display_name, "Round #{get_field(cs, :number)}")
  end

  def add_display_name_if_missing(cs), do: cs

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
