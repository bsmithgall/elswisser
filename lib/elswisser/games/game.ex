defmodule Elswisser.Games.Game do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  schema "games" do
    field(:game_link, :string)
    field(:pgn, :string)
    field(:result, :integer)

    belongs_to(:round, Elswisser.Rounds.Round)
    belongs_to(:tournament, Elswisser.Tournaments.Tournament)
    belongs_to(:white, Elswisser.Players.Player)
    belongs_to(:black, Elswisser.Players.Player)

    timestamps()
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:white_id, :black_id, :result, :round_id, :game_link, :tournament_id, :pgn])
    |> validate_required([:white_id, :black_id, :round_id, :tournament_id])
  end

  def from() do
    from g in Elswisser.Games.Game, as: :game
  end

  def where_id(query, id) do
    from g in query, where: g.id == ^id
  end

  def where_tournament_id(query, tournament_id) do
    from [..., game: g] in query, where: g.tournament_id == ^tournament_id
  end

  def where_round_id(query, round_id) do
    from g in query, where: g.round_id == ^round_id
  end

  def where_player_id(query, player_id) do
    from [..., game: g] in query, where: g.white_id == ^player_id or g.black_id == ^player_id
  end

  def with_white_player(query) do
    from [..., game: g] in query,
      left_join: w in assoc(g, :white),
      as: :white
  end

  def with_black_player(query) do
    from [..., game: g] in query,
      left_join: b in assoc(g, :black),
      as: :black
  end

  def preload_players(query) do
    from [game: g, white: w, black: b] in query, preload: [white: w, black: b]
  end

  def select_white_id(query) do
    from [game: g] in query, select: g.white_id
  end

  def select_black_id(query) do
    from [game: g] in query, select: g.white_id
  end
end
