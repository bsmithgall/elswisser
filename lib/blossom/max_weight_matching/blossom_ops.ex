defmodule Blossom.MaxWeightMatching.BlossomOps do
  @moduledoc """
  Blossom creation and navigation operations.

  This module provides functions to create non-trivial blossoms from alternating
  cycles and to navigate through blossoms during augmentation.
  """

  alias Blossom.MaxWeightMatching.Blossom.NonTrivial
  alias Blossom.MaxWeightMatching.Blossom, as: BlossomModule
  alias Blossom.MaxWeightMatching.Context
  alias Blossom.MaxWeightMatching.AlternatingPath
  alias Blossom.MaxWeightMatching.LeastSlack

  @doc """
  Construct a path through a blossom from sub-blossom to base.

  Given a non-trivial blossom and one of its sub-blossoms, returns the path
  from that sub-blossom to the base of the blossom (which is in subblossom_ids[0]).

  The path walks around the blossom in the direction that uses an even number
  of edges (ensuring the path has odd length for alternating path properties).

  ## Parameters

  - `blossom` - The non-trivial blossom to navigate through
  - `sub_id` - The ID of the sub-blossom to start from

  ## Returns

  A tuple `{nodes, edges}` where:
  - `nodes` - List of sub-blossom IDs from `sub` to base
  - `edges` - List of edges connecting consecutive sub-blossoms

  ## Examples

      # For a 5-blossom [A, B, C, D, E] with edges [e0, e1, e2, e3, e4]:
      # If starting from position 2 (C), walk backwards: [C, B, A]
      # If starting from position 3 (D), walk forwards: [D, E, A]
  """
  @spec find_path_through_blossom(NonTrivial.t(), reference()) ::
          {[reference()], [{non_neg_integer(), non_neg_integer()}]}
  def find_path_through_blossom(%NonTrivial{} = blossom, sub_id) do
    p = Enum.find_index(blossom.subblossom_ids, &(&1 == sub_id))

    if p == nil do
      raise ArgumentError, "sub_id not found in blossom's subblossom_ids"
    end

    if rem(p, 2) == 0 do
      nodes = blossom.subblossom_ids |> Enum.take(p + 1) |> Enum.reverse()

      edges =
        if p == 0 do
          []
        else
          blossom.edges
          |> Enum.take(p)
          |> Enum.reverse()
          |> Enum.map(fn {i, j} -> {j, i} end)
        end

      {nodes, edges}
    else
      n = length(blossom.subblossom_ids)

      nodes =
        Enum.slice(blossom.subblossom_ids, p..(n - 1)) ++
          [Enum.at(blossom.subblossom_ids, 0)]

      edges = Enum.slice(blossom.edges, p..(n - 1))

      {nodes, edges}
    end
  end

  @doc """
  Create a new blossom from an alternating cycle.

  Takes an alternating path that forms a cycle (starts and ends in the same
  top-level blossom) and creates a new non-trivial S-blossom containing all
  the sub-blossoms along the cycle.

  ## Operations performed:

  1. Extract sub-blossoms from the cycle path
  2. Create new NonTrivial blossom with label :s
  3. Link sub-blossoms to new parent
  4. Update vertex-to-blossom mappings
  5. Enqueue former T-vertices for scanning
  6. Merge least-slack edge tracking

  ## Parameters

  - `ctx` - The current matching context
  - `path` - The alternating path forming a cycle

  ## Returns

  Updated context with the new blossom.
  """
  @spec make_blossom(Context.t(), AlternatingPath.t()) :: Context.t()
  def make_blossom(%Context{} = ctx, %AlternatingPath{edges: path_edges}) do
    # Path must be odd-length cycle (>= 3 edges)
    n = length(path_edges)

    if n < 3 do
      raise ArgumentError, "make_blossom: path must have at least 3 edges, got #{n}"
    end

    if rem(n, 2) != 1 do
      raise ArgumentError, "make_blossom: path must have odd length, got #{n}"
    end

    # Extract sub-blossoms in cycle order
    subblossom_ids =
      Enum.map(path_edges, fn {x, _y} ->
        Context.get_vertex_blossom_id(ctx, x)
      end)

    # Get the first sub-blossom (contains base vertex and tree_edge)
    first_sub = Context.get_blossom(ctx, hd(subblossom_ids))

    if first_sub.label != :s do
      raise ArgumentError, "make_blossom: first sub-blossom must have label :s"
    end

    # Create the new blossom
    blossom = NonTrivial.new(subblossom_ids, path_edges, first_sub.base_vertex)

    blossom = %{blossom | label: :s, tree_edge: first_sub.tree_edge}

    # Add the new blossom to context
    ctx = Context.add_blossom(ctx, blossom)

    # Update parent_id for all sub-blossoms
    ctx =
      Enum.reduce(subblossom_ids, ctx, fn sub_id, acc ->
        Context.update_blossom(acc, sub_id, parent_id: blossom.id)
      end)

    # Update vertex_top_blossom_id for all vertices in the new blossom
    all_vertices = Context.blossom_vertices(ctx, blossom.id)
    ctx = Context.set_vertices_blossom(ctx, all_vertices, blossom.id)

    # Enqueue vertices from former T-sub-blossoms
    # (they now belong to an S-blossom and need to be scanned)
    vertices_to_enqueue =
      subblossom_ids
      |> Enum.filter(fn sub_id ->
        Context.get_blossom(ctx, sub_id).label == :t
      end)
      |> Enum.flat_map(fn sub_id ->
        BlossomModule.vertices(sub_id, ctx.blossoms)
      end)

    ctx = Context.enqueue(ctx, vertices_to_enqueue)

    # Merge least-slack edge tracking
    LeastSlack.merge_blossoms(ctx, blossom.id)
  end
end
