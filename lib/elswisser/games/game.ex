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
    |> unique_constraint(:unique_white_players, name: :games_white_id_round_id_unique_idx)
    |> unique_constraint(:unique_black_players, name: :games_black_id_round_id_unique_idx)
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

  def where_unfinished(query) do
    from [..., game: g] in query, where: is_nil(g.result)
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
    from [game: g] in query, select: g.black_id
  end

  @doc """
  Given a game and an existing roster, load a :white and :black player. We do it
  this way because we don't really have an easy way of doing this with a
  preloads from a query unfortunately; since we have multiple :belongs_to, there
  isn't really a clean way of dealing with it.
  """
  def load_players_from_roster(%Elswisser.Games.Game{} = game, roster) when is_list(roster) do
    from_roster =
      Enum.reduce(roster, %{}, fn
        white, acc when white.id == game.white_id -> Map.put(acc, :white, white)
        black, acc when black.id == game.black_id -> Map.put(acc, :black, black)
        _, acc -> acc
      end)

    Map.merge(game, from_roster)
  end
end
