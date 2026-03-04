defmodule MaxWeightMatching.Slack do
  @moduledoc """
  Edge slack calculation for the maximum weight matching algorithm.

  Slack represents how "tight" an edge is with respect to the dual variables.
  An edge with zero slack is tight and can be part of the matching.
  """

  alias MaxWeightMatching.Context
  alias MaxWeightMatching.Graph

  @doc """
  Calculate 2x the slack of the edge at index `e`.

  The full LP slack of an edge (x, y) with weight w is:
    dual[x] + dual[y] + sum(z[B] for blossoms B containing both x and y) - w

  However, this function computes only the vertex dual contribution:
    2 * slack = vertex_dual_2x[x] + vertex_dual_2x[y] - 2 * w

  This is correct for cross-blossom edges (the only case this function
  handles) because vertex duals are adjusted in lockstep with blossom
  duals during each delta step. When vertex x is inside an S-blossom,
  both vertex_dual_2x[x] decreases and the blossom's dual_var_2x
  increases by the same delta — so vertex duals implicitly absorb the
  blossom dual contributions for edges that cross blossom boundaries.
  The separate blossom dual (dual_var_2x) is only needed to know when
  a T-blossom should be expanded (delta4).

  We use 2x values throughout to maintain integer arithmetic when all
  edge weights are integers.

  ## Preconditions

  The edge must not be between vertices in the same top-level blossom.
  This is asserted in the function. (For blossom-internal edges, the
  blossom z[B] terms would be needed and are not included here.)

  ## Parameters

  - `ctx` - The current matching context
  - `e` - Index of the edge in `ctx.graph.edges`

  ## Returns

  The 2x slack value (integer if all weights are integers, float otherwise).

  ## Examples

      iex> # For edge {0, 1, 5} with vertex_dual_2x = %{0 => 10, 1 => 10}
      iex> # Slack = 10 + 10 - 2*5 = 10
      iex> Slack.edge_slack_2x(ctx, 0)
      10
  """
  @spec edge_slack_2x(Context.t(), non_neg_integer()) :: number()
  def edge_slack_2x(%Context{} = ctx, e) when is_integer(e) and e >= 0 do
    {x, y, w} = Graph.get_edge(ctx.graph, e)

    # Precondition: edge must not be internal to a blossom
    blossom_x = Map.fetch!(ctx.vertex_top_blossom_id, x)
    blossom_y = Map.fetch!(ctx.vertex_top_blossom_id, y)

    if blossom_x == blossom_y do
      raise ArgumentError,
            "edge_slack_2x called on edge #{e} between vertices #{x} and #{y} " <>
              "which are in the same top-level blossom"
    end

    dual_x = Map.fetch!(ctx.vertex_dual_2x, x)
    dual_y = Map.fetch!(ctx.vertex_dual_2x, y)

    dual_x + dual_y - 2 * w
  end
end
