defmodule Elswisser.Pairings.DoubleElimination do
  defdelegate create_all(tournament), to: Elswisser.Pairings.DoubleElimination.Create
  defdelegate next_pairings(rnd), to: Elswisser.Pairings.DoubleElimination.Next
end
