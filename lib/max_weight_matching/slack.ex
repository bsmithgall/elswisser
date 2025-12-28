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

  The slack of an edge (x, y) with weight w is:
    dual[x] + dual[y] - w

  We compute 2x this value to maintain integer arithmetic when all edge
  weights are integers:
    2 * slack = vertex_dual_2x[x] + vertex_dual_2x[y] - 2 * w

  ## Preconditions

  The edge must not be between vertices in the same top-level blossom.
  This is asserted in the function.

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
