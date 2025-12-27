defmodule Blossom.MaxWeightMatching.LeastSlack do
  @moduledoc """
  Least-slack edge tracking for the maximum weight matching algorithm.

  To calculate delta steps, the algorithm needs to find:
  - The least-slack edge between any S-vertex and an unlabeled vertex
  - The least-slack edge between any pair of top-level S-blossoms

  For each unlabeled vertex and T-vertex, we track the least-slack edge to
  any S-vertex. Tracking for T-vertices is done because they can become
  unlabeled if their T-blossom gets expanded.

  For each top-level S-blossom, we track the least-slack edge to any S-vertex
  not in the same blossom.

  For non-trivial S-blossoms, we also keep a list of edges to other S-blossoms.
  This list is used during blossom merging (Phase 8) to efficiently compute
  the new blossom's edge set.
  """

  alias Blossom.MaxWeightMatching.Blossom.Trivial
  alias Blossom.MaxWeightMatching.Blossom.NonTrivial
  alias Blossom.MaxWeightMatching.Context
  alias Blossom.MaxWeightMatching.Slack

  @doc """
  Reset all least-slack edge tracking.

  This clears:
  - `vertex_best_edge` for all vertices (set to -1)
  - `best_edge` for all blossoms (set to -1)
  - `best_edge_set` for all non-trivial blossoms (set to nil)

  Called at the start of each stage.

  ## Parameters

  - `ctx` - The current matching context

  ## Returns

  A new context with all edge tracking reset.
  """
  @spec reset(Context.t()) :: Context.t()
  def reset(%Context{} = ctx) do
    num_vertex = ctx.graph.num_vertex

    # Reset vertex_best_edge to -1 for all vertices
    vertex_best_edge = Map.new(0..(num_vertex - 1), fn v -> {v, -1} end)

    # Reset best_edge and best_edge_set for all blossoms
    blossoms =
      Map.new(ctx.blossoms, fn {id, blossom} ->
        updated =
          case blossom do
            %Trivial{} ->
              %{blossom | best_edge: -1}

            %NonTrivial{} ->
              %{blossom | best_edge: -1, best_edge_set: nil}
          end

        {id, updated}
      end)

    %{ctx | vertex_best_edge: vertex_best_edge, blossoms: blossoms}
  end

  @doc """
  Add an edge from an S-vertex to an unlabeled or T-vertex.

  Tracks the least-slack edge for each vertex. If this edge has less slack
  than the currently tracked edge for vertex `y`, it replaces the current one.

  ## Parameters

  - `ctx` - The current matching context
  - `y` - The target vertex (unlabeled or T-labeled)
  - `e` - The edge index
  - `slack` - The pre-calculated slack of edge `e`

  ## Returns

  A new context with updated edge tracking.
  """
  @spec add_vertex_edge(Context.t(), non_neg_integer(), non_neg_integer(), number()) ::
          Context.t()
  def add_vertex_edge(%Context{} = ctx, y, e, slack)
      when is_integer(y) and is_integer(e) and e >= 0 do
    best_edge = Map.fetch!(ctx.vertex_best_edge, y)

    should_update =
      if best_edge == -1 do
        true
      else
        best_slack = Slack.edge_slack_2x(ctx, best_edge)
        slack < best_slack
      end

    if should_update do
      %{ctx | vertex_best_edge: Map.put(ctx.vertex_best_edge, y, e)}
    else
      ctx
    end
  end

  @doc """
  Find the least-slack edge between any S-vertex and unlabeled vertex.

  Iterates through all vertices with unlabeled top-level blossoms and finds
  the edge with minimum slack.

  ## Parameters

  - `ctx` - The current matching context

  ## Returns

  A tuple `{edge_index, slack}` where:
  - `edge_index` is the index of the least-slack edge, or -1 if none found
  - `slack` is the 2x slack of that edge, or 0 if none found
  """
  @spec get_best_vertex_edge(Context.t()) :: {integer(), number()}
  def get_best_vertex_edge(%Context{} = ctx) do
    0..(ctx.graph.num_vertex - 1)
    |> Enum.reduce({-1, 0}, fn x, {best_index, best_slack} ->
      blossom = Context.get_vertex_blossom(ctx, x)

      if blossom.label == :none do
        e = Map.fetch!(ctx.vertex_best_edge, x)

        if e != -1 do
          slack = Slack.edge_slack_2x(ctx, e)

          if best_index == -1 or slack < best_slack do
            {e, slack}
          else
            {best_index, best_slack}
          end
        else
          {best_index, best_slack}
        end
      else
        {best_index, best_slack}
      end
    end)
  end

  @doc """
  Initialize edge tracking for a new S-blossom.

  For trivial blossoms, this is a no-op (just asserts best_edge == -1).
  For non-trivial blossoms, initializes `best_edge_set` to an empty list.

  ## Parameters

  - `ctx` - The current matching context
  - `blossom_id` - The ID of the new S-blossom

  ## Returns

  A new context with the blossom's edge tracking initialized.
  """
  @spec new_blossom(Context.t(), reference()) :: Context.t()
  def new_blossom(%Context{} = ctx, blossom_id) when is_reference(blossom_id) do
    blossom = Context.get_blossom(ctx, blossom_id)

    # Assert preconditions
    if blossom.best_edge != -1 do
      raise ArgumentError, "new_blossom: best_edge must be -1, got #{blossom.best_edge}"
    end

    case blossom do
      %Trivial{} ->
        # Nothing to do for trivial blossoms
        ctx

      %NonTrivial{best_edge_set: best_edge_set} ->
        if best_edge_set != nil do
          raise ArgumentError, "new_blossom: best_edge_set must be nil for new blossom"
        end

        Context.update_blossom(ctx, blossom_id, best_edge_set: [])
    end
  end

  @doc """
  Add an edge between the specified S-blossom and another S-blossom.

  Updates the blossom's `best_edge` if this edge has less slack than the
  current best. For non-trivial blossoms, also appends the edge to
  `best_edge_set` for use during future blossom merging.

  ## Parameters

  - `ctx` - The current matching context
  - `blossom_id` - The ID of the S-blossom to update
  - `e` - The edge index
  - `slack` - The pre-calculated slack of edge `e`

  ## Returns

  A new context with updated edge tracking.
  """
  @spec add_blossom_edge(Context.t(), reference(), non_neg_integer(), number()) :: Context.t()
  def add_blossom_edge(%Context{} = ctx, blossom_id, e, slack)
      when is_reference(blossom_id) and is_integer(e) and e >= 0 do
    blossom = Context.get_blossom(ctx, blossom_id)

    # Determine if we should update best_edge
    {should_update_best, _} =
      if blossom.best_edge == -1 do
        {true, slack}
      else
        best_slack = Slack.edge_slack_2x(ctx, blossom.best_edge)
        {slack < best_slack, best_slack}
      end

    # Build the updates
    updates =
      case blossom do
        %Trivial{} ->
          if should_update_best, do: [best_edge: e], else: []

        %NonTrivial{best_edge_set: best_edge_set} ->
          # Always append to best_edge_set for non-trivial blossoms
          base_updates = [best_edge_set: [e | best_edge_set]]

          if should_update_best do
            [{:best_edge, e} | base_updates]
          else
            base_updates
          end
      end

    if updates == [] do
      ctx
    else
      Context.update_blossom(ctx, blossom_id, updates)
    end
  end

  @doc """
  Find the least-slack edge between any pair of top-level S-blossoms.

  Iterates through all top-level S-blossoms (those with `label == :s` and
  `parent_id == nil`) and finds the edge with minimum slack.

  ## Parameters

  - `ctx` - The current matching context

  ## Returns

  A tuple `{edge_index, slack}` where:
  - `edge_index` is the index of the least-slack edge, or -1 if none found
  - `slack` is the 2x slack of that edge, or 0 if none found
  """
  @spec get_best_blossom_edge(Context.t()) :: {integer(), number()}
  def get_best_blossom_edge(%Context{} = ctx) do
    ctx.blossoms
    |> Map.values()
    |> Enum.filter(fn blossom ->
      blossom.label == :s and blossom.parent_id == nil
    end)
    |> Enum.reduce({-1, 0}, fn blossom, {best_index, best_slack} ->
      e = blossom.best_edge

      if e != -1 do
        slack = Slack.edge_slack_2x(ctx, e)

        if best_index == -1 or slack < best_slack do
          {e, slack}
        else
          {best_index, best_slack}
        end
      else
        {best_index, best_slack}
      end
    end)
  end
end
