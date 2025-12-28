defmodule MaxWeightMatching.AlternatingPath do
  @moduledoc """
  Alternating path tracing for the blossom algorithm.

  An alternating path is a sequence of edges between top-level blossoms where
  matched and unmatched edges alternate. When tracing from two S-vertices,
  we either find:
  - An augmenting path (vertices in different alternating trees)
  - A blossom cycle (vertices in the same alternating tree)
  """

  alias MaxWeightMatching.Context

  @type t :: %__MODULE__{
          edges: [{non_neg_integer(), non_neg_integer()}]
        }

  defstruct [:edges]

  @doc """
  Trace back through alternating trees from vertices `x` and `y`.

  If both vertices are part of the same alternating tree, this discovers
  a new blossom. The returned path starts and ends in the same sub-blossom.

  If the vertices are in different alternating trees, this discovers an
  augmenting path that starts and ends in unmatched vertices.

  Time: O(k) for blossom discovery where k is sub-blossom count,
        O(n) for augmenting path discovery.

  ## Parameters

  - `ctx` - The current matching context
  - `x` - First vertex (must be in an S-blossom)
  - `y` - Second vertex (must be in an S-blossom)

  ## Returns

  Tuple `{path, ctx}` where path is an AlternatingPath and ctx has all
  markers cleared.
  """
  @spec trace_alternating_paths(Context.t(), non_neg_integer(), non_neg_integer()) ::
          {t(), Context.t()}
  def trace_alternating_paths(%Context{} = ctx, x, y) do
    xedges = [{x, y}]
    yedges = [{y, x}]

    {first_common_id, xedges, yedges, marked_blossom_ids, ctx} =
      trace_loop(ctx, x, y, xedges, yedges, [])

    ctx = clear_markers(ctx, marked_blossom_ids)

    yedges =
      if first_common_id != nil do
        trim_to_common_ancestor(ctx, yedges, first_common_id)
      else
        yedges
      end

    path_edges = Enum.reverse(xedges) ++ flip_edges(Enum.drop(yedges, 1))

    path = %__MODULE__{edges: path_edges}

    {path, ctx}
  end

  # Both paths exhausted without finding common ancestor (different trees)
  defp trace_loop(ctx, -1, -1, xedges, yedges, marked) do
    {nil, xedges, yedges, marked, ctx}
  end

  # x exhausted: swap to continue tracing y
  defp trace_loop(ctx, -1, y, xedges, yedges, marked) do
    trace_loop(ctx, y, -1, yedges, xedges, marked)
  end

  # Active vertex: get its blossom and process
  defp trace_loop(ctx, x, y, xedges, yedges, marked) do
    bx = Context.get_vertex_blossom(ctx, x)
    process_trace_step(ctx, x, y, xedges, yedges, marked, bx)
  end

  # Found a marked blossom: this is the common ancestor
  defp process_trace_step(ctx, _x, _y, xedges, yedges, marked, %{marker: true} = bx) do
    {bx.id, xedges, yedges, marked, ctx}
  end

  # Unmarked blossom: mark it and continue tracing
  defp process_trace_step(ctx, _x, y, xedges, yedges, marked, bx) do
    ctx = Context.update_blossom(ctx, bx.id, marker: true)
    marked = [bx.id | marked]
    {next_x, new_xedges} = advance_along_tree(bx.tree_edge, xedges)
    continue_trace(ctx, next_x, y, new_xedges, yedges, marked)
  end

  # At tree root (no tree_edge)
  defp advance_along_tree(nil, xedges), do: {-1, xedges}

  # Follow tree_edge to parent
  defp advance_along_tree({px, _py} = edge, xedges), do: {px, xedges ++ [edge]}

  # Alternate to y path if y is still active
  defp continue_trace(ctx, next_x, y, xedges, yedges, marked) when y != -1 do
    trace_loop(ctx, y, next_x, yedges, xedges, marked)
  end

  # y exhausted: continue with x only
  defp continue_trace(ctx, next_x, y, xedges, yedges, marked) do
    trace_loop(ctx, next_x, y, xedges, yedges, marked)
  end

  defp clear_markers(ctx, blossom_ids) do
    Enum.reduce(blossom_ids, ctx, fn id, acc ->
      Context.update_blossom(acc, id, marker: false)
    end)
  end

  defp trim_to_common_ancestor(ctx, yedges, common_id) do
    yedges
    |> Enum.reverse()
    |> Enum.drop_while(fn {v, _} -> Context.get_vertex_blossom_id(ctx, v) != common_id end)
    |> Enum.reverse()
  end

  defp flip_edges(edges) do
    Enum.map(edges, fn {a, b} -> {b, a} end)
  end
end
