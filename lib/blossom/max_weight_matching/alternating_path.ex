defmodule Blossom.MaxWeightMatching.AlternatingPath do
  @moduledoc """
  Alternating path tracing for the blossom algorithm.

  An alternating path is a sequence of edges between top-level blossoms where
  matched and unmatched edges alternate. When tracing from two S-vertices,
  we either find:
  - An augmenting path (vertices in different alternating trees)
  - A blossom cycle (vertices in the same alternating tree)
  """

  alias Blossom.MaxWeightMatching.Context

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

  # Alternates between tracing x and y paths to bound search time by blossom size
  defp trace_loop(ctx, x, y, xedges, yedges, marked) when x == -1 and y == -1 do
    {nil, xedges, yedges, marked, ctx}
  end

  defp trace_loop(ctx, x, y, xedges, yedges, marked) do
    if x == -1 do
      trace_loop(ctx, y, -1, yedges, xedges, marked)
    else
      bx = Context.get_vertex_blossom(ctx, x)

      if bx.marker do
        {bx.id, xedges, yedges, marked, ctx}
      else
        ctx = Context.update_blossom(ctx, bx.id, marker: true)
        marked = [bx.id | marked]

        {x, xedges} =
          case bx.tree_edge do
            nil -> {-1, xedges}
            {px, _py} -> {px, xedges ++ [bx.tree_edge]}
          end

        if y != -1 do
          trace_loop(ctx, y, x, yedges, xedges, marked)
        else
          trace_loop(ctx, x, y, xedges, yedges, marked)
        end
      end
    end
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
