defmodule Elswisser.Scores.Score do
  use Ecto.Schema
  alias Elswisser.Players.Player
  alias Elswisser.Scores.Score
  alias Elswisser.Pairings.Bye

  embedded_schema do
    field :player_id, :integer
    field :opponents, {:array, :integer}, default: []
    field :results, {:array, :integer}, default: []
    field :score, :integer, default: 0
    field :modmed, :integer, default: 0
    field :solkoff, :integer, default: 0
    field :cumulative_sum, :integer, default: 0
    field :cumulative_opp, :integer, default: 0
    field :nblack, :integer, default: 0
    field :lastwhite, :boolean
    field :rating_change, :integer, default: 0
    embeds_one :player, Player
  end

  def had_bye?(%Score{} = score) do
    Enum.any?(score.opponents, fn o -> o == Bye.bye_player_id() end)
  end
end
