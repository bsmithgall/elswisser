defmodule Elswisser.Players.Player do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  schema "players" do
    field(:name, :string)
    field(:rating, :integer)

    has_many(:white_games, Elswisser.Games.Game, foreign_key: :white_id)
    has_many(:black_games, Elswisser.Games.Game, foreign_key: :black_id)

    many_to_many :tournaments, Elswisser.Tournaments.Tournament,
      join_through: Elswisser.Tournaments.TournamentPlayer,
      on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(player, attrs) do
    player
    |> cast(attrs, [:name, :rating])
    |> validate_required([:name, :rating])
  end

  def from do
    from p in Elswisser.Players.Player, as: :player
  end

  def where_id(query, id) when is_binary(id) when is_integer(id) do
    from p in query, where: p.id == ^id
  end

  def where_id(query, ids) when is_list(ids) do
    from p in query, where: p.id in ^ids
  end

  def with_games(query) do
    query |> with_white_games() |> with_black_games()
  end

  defp with_white_games(query) do
    from p in query,
      left_join: w in assoc(p, :white_games),
      as: :white_games,
      preload: [white_games: w]
  end

  defp with_black_games(query) do
    from p in query,
      left_join: b in assoc(p, :black_games),
      as: :black_games,
      preload: [black_games: b]
  end

  def with_games_for_tournament(query, tournament_id) do
    tournament_games =
      from(g in Elswisser.Games.Game, as: :game)
      |> Elswisser.Games.Game.where_tournament_id(tournament_id)

    from p in query,
      left_join: w in subquery(tournament_games),
      on: p.id == w.white_id,
      as: :white_games,
      left_join: b in subquery(tournament_games),
      on: p.id == b.white_id,
      as: :black_games,
      preload: [black_games: b, white_games: w]
  end

  @doc """
  Given a player with games loaded in, join them together and order them by the
  round ID.
  """
  def all_games(%Elswisser.Players.Player{} = player) do
    Enum.sort_by(player.white_games ++ player.black_games, & &1.round_id)
  end
end
