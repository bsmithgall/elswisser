defmodule MaxWeightMatching.Stepper.Snapshot do
  @moduledoc """
  Extracts displayable state from a `Context`.

  Translates opaque `make_ref()` blossom IDs into vertex groups and
  produces a renderer-agnostic map suitable for any visualization consumer.
  """

  alias MaxWeightMatching.Context
  alias MaxWeightMatching.Blossom.NonTrivial

  @doc """
  Build a snapshot from the current algorithm context.

  ## Returns

  A map with:
  - `vertex_labels` — each vertex's current label (`:s`, `:t`, or `:none`)
  - `vertex_duals` — each vertex's 2× dual variable (raw internal value)
  - `matched_edges` — list of `{x, y}` pairs where `x < y`
  - `blossoms` — list of top-level non-trivial blossom groups
  - `edges` — the graph's edge map (immutable, same every step)
  - `queue` — list of S-vertices waiting to be scanned (front to back)
  """
  @spec from_context(Context.t()) :: MaxWeightMatching.Step.snapshot()
  def from_context(%Context{} = ctx) do
    n = ctx.graph.num_vertex

    %{
      vertex_labels: extract_vertex_labels(ctx, n),
      vertex_duals: extract_vertex_duals(ctx, n),
      matched_edges: extract_matched_edges(ctx, n),
      blossoms: extract_blossoms(ctx),
      edges: ctx.graph.edges,
      queue: :queue.to_list(ctx.queue)
    }
  end

  defp extract_vertex_labels(_ctx, n) when n == 0, do: %{}

  defp extract_vertex_labels(ctx, n) do
    Map.new(0..(n - 1), fn v ->
      {v, Context.get_vertex_blossom(ctx, v).label}
    end)
  end

  defp extract_vertex_duals(_ctx, n) when n == 0, do: %{}

  defp extract_vertex_duals(ctx, n) do
    Map.new(0..(n - 1), fn v ->
      {v, Map.fetch!(ctx.vertex_dual_2x, v)}
    end)
  end

  defp extract_matched_edges(_ctx, n) when n == 0, do: []

  defp extract_matched_edges(ctx, n) do
    0..(n - 1)
    |> Enum.reduce([], fn v, acc ->
      mate = Map.fetch!(ctx.vertex_mate, v)

      if mate != -1 and v < mate do
        [{v, mate} | acc]
      else
        acc
      end
    end)
    |> Enum.sort()
  end

  defp extract_blossoms(ctx) do
    # Collect all non-trivial blossoms, assigning stable integer IDs.
    # Each blossom records its direct member vertices and its parent
    # blossom index (if nested), so the JS can build compound nodes.
    non_trivials =
      ctx.blossoms
      |> Map.values()
      |> Enum.filter(&match?(%NonTrivial{}, &1))

    # Map from blossom ref → integer index
    id_map =
      non_trivials
      |> Enum.with_index()
      |> Map.new(fn {b, i} -> {b.id, i} end)

    Enum.map(non_trivials, fn blossom ->
      # Direct leaf vertices: walk subblossom_ids one level and collect
      # only Trivial children (NonTrivial children become their own group)
      direct_vertices =
        blossom.subblossom_ids
        |> Enum.flat_map(fn sub_id ->
          sub = Map.fetch!(ctx.blossoms, sub_id)

          case sub do
            %NonTrivial{} -> []
            trivial -> [trivial.base_vertex]
          end
        end)

      parent_idx =
        if blossom.parent_id, do: Map.get(id_map, blossom.parent_id), else: nil

      %{
        id: Map.fetch!(id_map, blossom.id),
        vertices: direct_vertices,
        parent: parent_idx,
        base: blossom.base_vertex,
        dual: blossom.dual_var_2x
      }
    end)
  end
end
