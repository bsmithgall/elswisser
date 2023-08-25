defmodule Elswisser.Scores.Score do
  use Ecto.Schema
  alias Elswisser.Players.Player

  embedded_schema do
    field :player_id, :integer
    field :opponents, {:array, :integer}
    field :results, {:array, :integer}
    field :score, :integer
    field :modmed, :integer
    field :solkoff, :integer
    field :cumulative_sum, :integer
    field :cumulative_opp, :integer
    field :nblack, :integer, default: 0
    field :lastwhite, :boolean
    embeds_one :player, Player
  end
end
