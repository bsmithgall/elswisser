defmodule Elswisser.Tournaments.Tournament do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias Elswisser.Tournaments.TournamentPlayer
  alias Elswisser.Rounds.Round
  alias Elswisser.Games.Game

  alias __MODULE__

  @types ~w[swiss single_elimination double_elimination round_robin]a
  @knockouts ~w[single_elimination double_elimination]a
  @match_formats ~w[best_of first_to]a

  schema "tournaments" do
    field(:name, :string)
    field(:length, :integer)

    field(:type, Ecto.Enum, values: @types)
    field(:match_format, Ecto.Enum, values: @match_formats, default: :best_of)
    field(:points_to_win, :integer, default: 1)
    field(:allow_draws, :boolean, default: true)

    has_many(:tournament_players, TournamentPlayer, on_replace: :delete)
    has_many(:players, through: [:tournament_players, :player])

    has_many(:rounds, Round)
    has_many(:games, Game)

    timestamps()
  end

  @doc false
  def changeset(tournament, attrs) do
    tournament
    |> cast(attrs, [:name, :length, :type, :match_format, :points_to_win, :allow_draws])
    |> validate_required([:name, :length, :type, :match_format, :points_to_win, :allow_draws])
    |> validate_inclusion(:type, @types)
    |> validate_inclusion(:match_format, @match_formats)
    |> validate_number(:points_to_win, greater_than: 0)
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
    from([round: r, match: m, game: g, white: w, black: b, player: p, opening: o] in query,
      preload: [
        rounds:
          {r,
           matches: {m, games: {g, white: w, black: b}},
           games: {g, white: w, black: b, opening: o}},
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

  def knockout?(type) when is_binary(type), do: knockout?(String.to_existing_atom(type))

  def knockout?(%Tournament{} = tournament), do: knockout?(tournament.type)

  def knockout?(type) when is_atom(type), do: type in @knockouts

  defguard is_knockout?(type) when is_atom(type) and type in @knockouts
end
