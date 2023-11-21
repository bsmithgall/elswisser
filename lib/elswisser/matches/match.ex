defmodule Elswisser.Matches.Match do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  schema "matches" do
    field :board, :integer
    field :display_order, :integer

    belongs_to(:round, Elswisser.Rounds.Round)
    has_many(:games, Elswisser.Games.Game)

    belongs_to(:winner, Elswisser.Players.Player)
    belongs_to(:winner_to, __MODULE__)
    belongs_to(:loser_to, __MODULE__)

    timestamps()
  end

  @doc false
  def changeset(match, attrs) do
    match
    |> cast(attrs, [:board, :display_order, :round_id, :winner_id, :winner_to_id, :loser_to_id])
    |> validate_required([:board, :display_order, :round_id])
  end

  def from() do
    from(m in __MODULE__, as: :match)
  end
end
