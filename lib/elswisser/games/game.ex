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
    |> validate_required([:white_id, :black_id, :result, :round_id, :tournament_id])
  end

  def where_id(query, id) do
    from g in query, where: g.id == ^id
  end

  def where_round_id(query, round_id) do
    from g in query, where: g.round_id == ^round_id
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
    from [game: g, white: w, black: b] in query, preload: [games: {g, white: w, black: b}]
  end
end
