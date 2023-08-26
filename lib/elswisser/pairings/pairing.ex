defmodule Elswisser.Pairings.Pairing do
  alias Elswisser.Scores.Score

  use Ecto.Schema

  embedded_schema do
    field :player_id, :integer
    field :upperhalf, :boolean, default: false
    field :half_idx, :integer
    embeds_one :score, Score
  end
end
