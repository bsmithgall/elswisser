defmodule Elswisser.Pairings.DoubleElim.Rounds do
  def label(match_graph) do
    match_graph
    |> Enum.map(&{&1.round, &1.type})
    |> Enum.uniq()
    |> Enum.group_by(fn {_, type} -> name(type) end, fn {idx, _} -> idx end)
    |> Enum.reduce(%{}, fn {label, ids}, labels ->
      ids
      |> Enum.with_index(1)
      |> Enum.reduce(labels, fn {id, idx}, acc -> Map.put(acc, id, "#{label} #{idx}") end)
    end)
  end

  defp name(:lr), do: "Losers"
  defp name(:lm), do: "Losers"
  defp name(:w), do: "Winners"
  defp name(:c), do: "Championship"
end
