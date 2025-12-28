defmodule MaxWeightMatching.Label do
  @moduledoc """
  Label assignment for alternating trees in the blossom algorithm.

  During each stage of the algorithm, we grow alternating trees from unmatched
  vertices. Vertices (and blossoms) are labeled S or T as they are added to
  the tree:
  - S-blossoms are "outer" nodes, reachable via an even number of edges from root
  - T-blossoms are "inner" nodes, reachable via an odd number of edges from root

  S-blossoms and T-blossoms alternate along tree paths. The root of each tree
  is an S-blossom containing an unmatched vertex.
  """

  alias MaxWeightMatching.Context
  alias MaxWeightMatching.LeastSlack
  alias MaxWeightMatching.BlossomOps
  alias MaxWeightMatching.Blossom.NonTrivial

  @doc """
  Assign label S to the unlabeled blossom containing vertex `x`.

  If vertex `x` is matched, the blossom is attached to the alternating tree
  via its matched edge. If vertex `x` is unmatched, the blossom becomes the
  root of an alternating tree.

  All vertices in the newly labeled blossom are added to the scan queue.

  ## Preconditions

  - `x` is an unlabeled vertex
  - `x` is either unmatched or matched to a T-vertex via a tight edge

  ## Parameters

  - `ctx` - The current matching context
  - `x` - The vertex whose blossom should be labeled S

  ## Returns

  A new context with the blossom labeled S and its vertices queued for scanning.
  """
  @spec assign_label_s(Context.t(), non_neg_integer()) :: Context.t()
  def assign_label_s(%Context{} = ctx, x) when is_integer(x) and x >= 0 do
    bx = Context.get_vertex_blossom(ctx, x)
    bx_id = Context.get_vertex_blossom_id(ctx, x)

    if bx.label != :none do
      raise ArgumentError,
            "assign_label_s: blossom must be unlabeled, got #{inspect(bx.label)}"
    end

    y = Map.fetch!(ctx.vertex_mate, x)

    tree_edge =
      cond do
        y == -1 and bx.base_vertex != x ->
          raise ArgumentError,
                "assign_label_s: unmatched vertex #{x} must be base vertex, got #{bx.base_vertex}"

        y == -1 ->
          nil

        Context.get_vertex_blossom(ctx, y).label != :t ->
          raise ArgumentError,
                "assign_label_s: mate's blossom must be T-labeled, got #{inspect(Context.get_vertex_blossom(ctx, y).label)}"

        true ->
          {y, x}
      end

    ctx = Context.update_blossom(ctx, bx_id, label: :s, tree_edge: tree_edge)
    ctx = LeastSlack.new_blossom(ctx, bx_id)
    vertices = Context.blossom_vertices(ctx, bx_id)
    Context.enqueue(ctx, vertices)
  end

  @doc """
  Assign label T to the unlabeled blossom containing vertex `y`.

  Attaches the blossom to the alternating tree via edge `(x, y)`.
  Then immediately assigns label S to the mate of the T-blossom's base vertex.

  ## Preconditions

  - `x` is an S-vertex
  - `y` is an unlabeled, matched vertex
  - There is a tight edge between vertices `x` and `y`

  ## Parameters

  - `ctx` - The current matching context
  - `x` - The S-vertex on one end of the tight edge
  - `y` - The unlabeled vertex to be labeled T

  ## Returns

  A new context with the blossom labeled T and its mate labeled S.
  """
  @spec assign_label_t(Context.t(), non_neg_integer(), non_neg_integer()) :: Context.t()
  def assign_label_t(%Context{} = ctx, x, y)
      when is_integer(x) and x >= 0 and is_integer(y) and y >= 0 do
    bx = Context.get_vertex_blossom(ctx, x)

    if bx.label != :s do
      raise ArgumentError,
            "assign_label_t: vertex #{x} must be in S-blossom, got #{inspect(bx.label)}"
    end

    # Expand zero-dual blossoms before assigning T label
    {ctx, by, by_id} = expand_zero_dual_blossoms(ctx, y)

    if by.label != :none do
      raise ArgumentError,
            "assign_label_t: blossom must be unlabeled, got #{inspect(by.label)}"
    end

    ctx = Context.update_blossom(ctx, by_id, label: :t, tree_edge: {x, y})

    # Re-fetch blossom after update to get current state
    by = Context.get_blossom(ctx, by_id)
    z = Map.fetch!(ctx.vertex_mate, by.base_vertex)

    if z == -1 do
      raise ArgumentError,
            "assign_label_t: T-blossom base vertex #{by.base_vertex} must be matched"
    end

    assign_label_s(ctx, z)
  end

  # Expand any zero-dual non-trivial blossoms containing vertex y
  # Returns {updated_ctx, current_blossom, current_blossom_id}
  defp expand_zero_dual_blossoms(ctx, y) do
    by = Context.get_vertex_blossom(ctx, y)
    by_id = Context.get_vertex_blossom_id(ctx, y)

    case by do
      %NonTrivial{dual_var: 0} ->
        ctx = BlossomOps.expand_unlabeled_blossom(ctx, by_id)
        expand_zero_dual_blossoms(ctx, y)

      _ ->
        {ctx, by, by_id}
    end
  end
end
