defmodule Elswisser.Pairings.DoubleElim.Bracket do
  alias Elswisser.Pairings.DoubleElim.Rounds
  alias Elswisser.Pairings.DoubleElim.MatchGraph

  @doc """
  Given a list of players, generate a pairing bracket for them.
  """
  def generate(players) do
    match_graph = length(players) |> MatchGraph.generate()

    matches_by_id = Enum.into(match_graph, %{}, &{&1.id, &1})
    labels = Rounds.label(match_graph)

    {matches_by_id, labels}
  end
end
