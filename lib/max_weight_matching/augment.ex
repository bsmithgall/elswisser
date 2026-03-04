defmodule MaxWeightMatching.Augment do
  @moduledoc """
  Matching augmentation for the blossom algorithm.

  Augments the current matching along an augmenting path by flipping
  matched and unmatched edges.
  """

  alias MaxWeightMatching.Context
  alias MaxWeightMatching.AlternatingPath
  alias MaxWeightMatching.BlossomOps
  alias MaxWeightMatching.Blossom.NonTrivial

  @doc """
  Augment the matching through the specified augmenting path.

  The augmenting path must start and end in an unmatched vertex (or a
  blossom with unmatched base). After augmenting, those vertices will
  be matched, and all matched edges on the path become unmatched while
  unmatched edges become matched.

  For non-trivial blossoms along the path, `augment_blossom/3` is called
  to rotate the blossom and update internal matching.

  Time: O(n)

  ## Parameters

  - `ctx` - The current matching context
  - `path` - An augmenting path from `trace_alternating_paths`

  ## Returns

  A new context with the matching augmented along the path.
  """
  @spec augment_matching(Context.t(), AlternatingPath.t()) :: Context.t()
  def augment_matching(%Context{} = ctx, %AlternatingPath{edges: edges}) do
    # Walk through the edges that were unmatched before augmenting
    # (edges at even indices: 0, 2, 4, ...)
    edges
    |> Enum.take_every(2)
    |> Enum.reduce(ctx, fn {x, y}, acc ->
      # Augment through non-trivial blossoms on either side of this edge
      acc = augment_if_nontrivial(acc, x)
      acc = augment_if_nontrivial(acc, y)

      # Update vertex_mate for both endpoints
      vertex_mate =
        acc.vertex_mate
        |> Map.put(x, y)
        |> Map.put(y, x)

      %{acc | vertex_mate: vertex_mate}
    end)
  end

  # If vertex is in a non-trivial blossom, augment through it
  defp augment_if_nontrivial(ctx, vertex) do
    blossom = Context.get_vertex_blossom(ctx, vertex)

    case blossom do
      %NonTrivial{} ->
        trivial_id = Context.get_trivial_blossom_id(ctx, vertex)
        augment_blossom(ctx, blossom.id, trivial_id)

      _ ->
        ctx
    end
  end

  @doc """
  Augment along an alternating path through the specified blossom.

  Augments from sub-blossom `sub_id` to the base vertex of the blossom.
  Recursively augments any non-trivial sub-blossoms on the alternating path.

  Time: O(n)

  ## Parameters

  - `ctx` - The current matching context
  - `blossom_id` - The ID of the top-level blossom to augment through
  - `sub_id` - The ID of the sub-blossom to start from

  ## Returns

  Updated context with matching augmented through the blossom.
  """
  @spec augment_blossom(Context.t(), reference(), reference()) :: Context.t()
  def augment_blossom(%Context{} = ctx, blossom_id, sub_id) do
    # Use an explicit stack to avoid deep recursion
    stack = [{blossom_id, sub_id}]
    augment_blossom_loop(ctx, stack)
  end

  defp augment_blossom_loop(ctx, []), do: ctx

  defp augment_blossom_loop(ctx, [{outer_blossom_id, sub_id} | rest]) do
    sub = Context.get_blossom(ctx, sub_id)

    # sub.parent_id should not be nil (sub is inside a blossom)
    if sub.parent_id == nil do
      raise ArgumentError, "augment_blossom: sub-blossom must have a parent"
    end

    blossom_id = sub.parent_id

    # If the direct parent is not the outer blossom, we need to continue
    # through the parent chain
    stack =
      if blossom_id != outer_blossom_id do
        # Continue augmenting through the parent of this blossom
        [{outer_blossom_id, blossom_id} | rest]
      else
        rest
      end

    # Augment through this blossom from sub to base
    {ctx, new_stack_items} = augment_blossom_rec(ctx, blossom_id, sub_id)
    augment_blossom_loop(ctx, new_stack_items ++ stack)
  end

  # Augment through a single blossom from sub to base
  # Returns {updated_ctx, new_stack_items}
  defp augment_blossom_rec(ctx, blossom_id, sub_id) do
    blossom = Context.get_blossom(ctx, blossom_id)

    # Walk through the blossom from sub to base
    {path_nodes, path_edges} = BlossomOps.find_path_through_blossom(blossom, sub_id)

    # Process pairs of edges at positions 0, 2, 4, ...
    # At each step p:
    #   path_nodes[p] was matched to path_nodes[p+1] before
    #   After: path_nodes[p+1] matched to path_nodes[p+2] via edge at p+1
    path_edges_t = List.to_tuple(path_edges)
    path_nodes_t = List.to_tuple(path_nodes)

    {ctx_after_mates, new_stack_items} =
      0..(length(path_edges) - 1)//2
      |> Enum.reduce({ctx, []}, fn p, {acc, stack_acc} ->
        # Pull edge at position p+1 into matching
        {x, y} = elem(path_edges_t, p + 1)

        vertex_mate =
          acc.vertex_mate
          |> Map.put(x, y)
          |> Map.put(y, x)

        acc = %{acc | vertex_mate: vertex_mate}

        # Check if sub-blossoms are non-trivial and need augmentation
        bx = Context.get_blossom(acc, elem(path_nodes_t, p + 1))
        by = Context.get_blossom(acc, elem(path_nodes_t, p + 2))

        stack_acc =
          case bx do
            %NonTrivial{} ->
              trivial_id = Context.get_trivial_blossom_id(acc, x)
              [{bx.id, trivial_id} | stack_acc]

            _ ->
              stack_acc
          end

        stack_acc =
          case by do
            %NonTrivial{} ->
              trivial_id = Context.get_trivial_blossom_id(acc, y)
              [{by.id, trivial_id} | stack_acc]

            _ ->
              stack_acc
          end

        {acc, stack_acc}
      end)

    # Rotate subblossom list so new base ends up at position 0
    p = Enum.find_index(blossom.subblossom_ids, &(&1 == sub_id))

    if p == nil do
      raise ArgumentError, "augment_blossom_rec: sub_id not found in blossom"
    end

    rotated_subblossoms =
      Enum.slice(blossom.subblossom_ids, p..-1//1) ++ Enum.take(blossom.subblossom_ids, p)

    rotated_edges = Enum.slice(blossom.edges, p..-1//1) ++ Enum.take(blossom.edges, p)

    sub = Context.get_blossom(ctx_after_mates, sub_id)

    ctx_rotated =
      Context.update_blossom(ctx_after_mates, blossom_id,
        subblossom_ids: rotated_subblossoms,
        edges: rotated_edges,
        base_vertex: sub.base_vertex
      )

    {ctx_rotated, new_stack_items}
  end
end
