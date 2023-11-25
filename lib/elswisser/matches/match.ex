defmodule Elswisser.Matches.Match do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  schema "matches" do
    field :board, :integer
    field :display_order, :integer

    belongs_to(:round, Elswisser.Rounds.Round)
    has_many(:games, Elswisser.Games.Game)

    timestamps()
  end

  @doc false
  def changeset(match, attrs) do
    match
    |> cast(attrs, [:board, :display_order, :round_id])
    |> validate_required([:board, :display_order, :round_id])
  end

  def from() do
    from(m in __MODULE__, as: :match)
  end

  def with_games(query) do
    from([match: m] in query, left_join: g in assoc(m, :games), as: :game)
  end

  def first_game_or_nil(nil), do: nil

  def first_game_or_nil(%__MODULE__{} = match) do
    Enum.at(match.games, 0)
  end
end
