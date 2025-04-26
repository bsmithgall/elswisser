defmodule Elswisser.Players.Player do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias Elswisser.Games.Game
  alias Elswisser.Tournaments.Tournament
  alias Elswisser.Tournaments.TournamentPlayer

  schema "players" do
    field(:name, :string)
    field(:rating, :integer)

    field(:chesscom, :string)
    field(:lichess, :string)
    field(:slack_id, :string)

    has_many(:white_games, Game, foreign_key: :white_id)
    has_many(:black_games, Game, foreign_key: :black_id)

    many_to_many(:tournaments, Tournament, join_through: TournamentPlayer, on_replace: :delete)

    timestamps()
  end

  @doc false
  def changeset(player, attrs) do
    player
    |> cast(attrs, [:name, :rating, :chesscom, :lichess, :slack_id])
    |> validate_required([:name, :rating])
  end

  @doc """
  Given a player with games loaded in, join them together and order them by the
  round ID.
  """
  def all_games(%Elswisser.Players.Player{} = player) do
    Enum.sort_by(player.white_games ++ player.black_games, & &1.round_id)
  end

  def with_k_factor(%{rating: rating} = player, games_played)
      when is_integer(games_played) do
    cond do
      games_played < 30 -> {player, 40}
      rating > 2100 -> {player, 10}
      true -> {player, 20}
    end
  end

  def from do
    from(p in Elswisser.Players.Player, as: :player)
  end

  def excluding_bye_player(query) do
    from([player: p] in query, where: p.id != -1)
  end

  def where_id(query, id) when is_binary(id) when is_integer(id) do
    from([player: p] in query, where: p.id == ^id)
  end

  def where_id(query, ids) when is_list(ids) do
    from([player: p] in query, where: p.id in ^ids)
  end

  def where_tournament_id(query, id) do
    from([player: p] in query,
      join: t in assoc(p, :tournaments),
      as: :tournament,
      where: t.id == ^id
    )
  end

  def where_not_matching(query, match_query) do
    from([player: p] in query,
      where: p.id not in subquery(match_query)
    )
  end

  def with_games(query) do
    query |> with_white_games() |> with_black_games()
  end

  def order_by_name(query) do
    from([player: p] in query,
      order_by: p.name
    )
  end

  defp with_white_games(query) do
    from(p in query,
      left_join: w in assoc(p, :white_games),
      as: :white_games
    )
  end

  defp with_black_games(query) do
    from(p in query,
      left_join: b in assoc(p, :black_games),
      as: :black_games
    )
  end

  defmodule Mini do
    use Ecto.Schema

    @primary_key false
    embedded_schema do
      field :name, :string
      field :rating, :integer
      field :chesscom, :string
      field :lichess, :string
      field :slack_id, :string
    end
  end
end
