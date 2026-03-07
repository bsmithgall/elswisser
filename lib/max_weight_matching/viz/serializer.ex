defmodule MaxWeightMatching.Viz.Serializer do
  @moduledoc """
  Converts a `Stepper.Step` into a JSON-safe map for push_event to the JS hook.
  """

  alias MaxWeightMatching.Stepper.Step

  @doc """
  Serialize a step to a plain map with no tuples or atoms (except in keys).
  """
  @spec serialize(Step.t()) :: map()
  def serialize(%Step{} = step) do
    %{
      type: step.type,
      detail: serialize_detail(step.detail),
      snapshot: serialize_snapshot(step.snapshot)
    }
  end

  defp serialize_snapshot(snap) do
    %{
      vertex_labels:
        Map.new(snap.vertex_labels, fn {v, label} ->
          {Integer.to_string(v), Atom.to_string(label)}
        end),
      vertex_duals:
        Map.new(snap.vertex_duals, fn {v, dual} ->
          {Integer.to_string(v), dual}
        end),
      matched_edges: Enum.map(snap.matched_edges, fn {x, y} -> [x, y] end),
      blossoms:
        Enum.map(snap.blossoms, fn b ->
          %{vertices: b.vertices, base: b.base, dual: b.dual}
        end),
      edges:
        Map.new(snap.edges, fn {k, {x, y, w}} ->
          {Integer.to_string(k), [x, y, w]}
        end)
    }
  end

  defp serialize_detail(detail) do
    Map.new(detail, fn
      {k, nil} -> {k, nil}
      {k, v} when is_boolean(v) -> {k, v}
      {k, v} when is_atom(v) -> {k, Atom.to_string(v)}
      {k, v} when is_list(v) -> {k, Enum.map(v, &serialize_detail_value/1)}
      {k, v} -> {k, v}
    end)
  end

  defp serialize_detail_value(nil), do: nil
  defp serialize_detail_value(v) when is_atom(v), do: Atom.to_string(v)
  defp serialize_detail_value(v) when is_tuple(v), do: Tuple.to_list(v)
  defp serialize_detail_value(v) when is_map(v), do: serialize_detail(v)
  defp serialize_detail_value(v), do: v
end
