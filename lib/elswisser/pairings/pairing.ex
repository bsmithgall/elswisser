defmodule Elswisser.Pairings.Pairing do
  defstruct player_id: -1,
            score: %Elswisser.Scores{},
            upperhalf: false,
            half_idx: -1
end
