defmodule Elswisser.Pairings.DoubleElimination.Rounds do
  alias Elswisser.Pairings.DoubleElimination.MatchGraph

  @doc """
  Generates round labels and types from the match graph.

  Groups rounds by bracket type (:w, :lm/:lr, :c), then numbers them sequentially
  within each group (e.g., "Winners 1", "Winners 2", "Losers 1", "Losers 2").
  Returns a map of round_number => {display_name, type}.
  """
  @spec labels_for(list(MatchGraph.t())) :: %{number() => {String.t(), String.t()}}
  def labels_for(match_graph) do
    match_graph
    |> Enum.map(&{&1.round, &1.type})
    |> Enum.uniq()
    |> Enum.group_by(fn {_, type} -> name(type) end, fn {idx, _} -> idx end)
    |> Enum.reduce(%{}, fn {{label, type}, ids}, labels ->
      ids
      |> Enum.sort()
      |> Enum.with_index(1)
      |> Enum.reduce(labels, fn {id, idx}, acc -> Map.put(acc, id, {"#{label} #{idx}", type}) end)
    end)
  end

  @spec name(atom()) :: {String.t(), String.t()}
  defp name(:lr), do: {"Losers", "loser"}
  defp name(:lm), do: {"Losers", "loser"}
  defp name(:w), do: {"Winners", "winner"}
  defp name(:c), do: {"Championship", "championship"}
end
