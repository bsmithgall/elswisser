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

  def where_id(query, id) when is_integer(id) do
    from p in query, where: p.id == ^id
  end

  def where_id(query, ids) when is_list(ids) do
    from p in query, where: p.id in ^ids
  end
end
