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
      best_edge == -1 or slack < Slack.edge_slack_2x(ctx, best_edge)

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
    |> Enum.reduce({-1, 0}, fn x, {best_index, best_slack} = acc ->
      blossom = Context.get_vertex_blossom(ctx, x)
      e = Map.fetch!(ctx.vertex_best_edge, x)

      cond do
        blossom.label != :none ->
          acc

        e == -1 ->
          acc

        best_index == -1 ->
          {e, Slack.edge_slack_2x(ctx, e)}

        true ->
          slack = Slack.edge_slack_2x(ctx, e)
          if slack < best_slack, do: {e, slack}, else: acc
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

    if blossom.best_edge != -1 do
      raise ArgumentError, "new_blossom: best_edge must be -1, got #{blossom.best_edge}"
    end

    case blossom do
      %Trivial{} ->
        ctx

      %NonTrivial{best_edge_set: nil} ->
        Context.update_blossom(ctx, blossom_id, best_edge_set: [])

      %NonTrivial{} ->
        raise ArgumentError, "new_blossom: best_edge_set must be nil for new blossom"
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

    should_update_best =
      blossom.best_edge == -1 or slack < Slack.edge_slack_2x(ctx, blossom.best_edge)

    case blossom do
      %Trivial{} when should_update_best ->
        Context.update_blossom(ctx, blossom_id, best_edge: e)

      %Trivial{} ->
        ctx

      %NonTrivial{best_edge_set: best_edge_set} when should_update_best ->
        Context.update_blossom(ctx, blossom_id,
          best_edge: e,
          best_edge_set: [e | best_edge_set]
        )

      %NonTrivial{best_edge_set: best_edge_set} ->
        Context.update_blossom(ctx, blossom_id, best_edge_set: [e | best_edge_set])
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
    |> Enum.filter(&(&1.label == :s and &1.parent_id == nil))
    |> Enum.reduce({-1, 0}, fn blossom, {best_index, best_slack} = acc ->
      e = blossom.best_edge

      cond do
        e == -1 ->
          acc

        best_index == -1 ->
          {e, Slack.edge_slack_2x(ctx, e)}

        true ->
          slack = Slack.edge_slack_2x(ctx, e)
          if slack < best_slack, do: {e, slack}, else: acc
      end
    end)
  end

  @doc """
  Update least-slack edge tracking after merging sub-blossoms into a new S-blossom.

  This function collects the least-slack edges from all S-labeled sub-blossoms,
  filters out edges that are now internal to the new blossom, and computes the
  new blossom's `best_edge` and `best_edge_set`.

  For trivial S-sub-blossoms, we scan their adjacent edges directly (happens at
  most once per vertex per stage, adding O(m) time per stage).

  For non-trivial S-sub-blossoms, we pull their existing `best_edge_set` and
  then clear it.

  ## Parameters

  - `ctx` - The current matching context (with new blossom already added)
  - `blossom_id` - The ID of the newly created blossom

  ## Returns

  Updated context with the new blossom's edge tracking set up.
  """
  @spec merge_blossoms(Context.t(), reference()) :: Context.t()
  def merge_blossoms(%Context{} = ctx, blossom_id) do
    blossom = Context.get_blossom(ctx, blossom_id)
    num_vertex = ctx.graph.num_vertex

    # State structure for tracking edges during merge:
    # - best_edge_to_blossom: Map from external blossom's base_vertex -> edge index
    #   (keeps only the least-slack edge to each external S-blossom)
    # - best_slack_to_blossom: Map from external blossom's base_vertex -> slack value
    # - best_edge: Overall least-slack edge to any external S-blossom
    # - best_slack: Slack of best_edge
    # - ctx: Context (may be modified when clearing sub-blossom edge sets)
    initial_state = %{
      best_edge_to_blossom: Map.new(0..(num_vertex - 1), fn v -> {v, -1} end),
      best_slack_to_blossom: Map.new(0..(num_vertex - 1), fn v -> {v, 0} end),
      best_edge: -1,
      best_slack: 0,
      ctx: ctx
    }

    # Process each S-labeled sub-blossom
    state =
      Enum.reduce(blossom.subblossom_ids, initial_state, fn sub_id, state ->
        sub = Context.get_blossom(state.ctx, sub_id)

        if sub.label != :s do
          state
        else
          {sub_edge_set, state} = get_sub_edge_set(state, sub)
          process_sub_edges(state, blossom, sub_edge_set)
        end
      end)

    # Extract compact best_edge_set list
    best_edge_set =
      state.best_edge_to_blossom
      |> Map.values()
      |> Enum.filter(&(&1 != -1))

    # Update the new blossom with best_edge and best_edge_set
    Context.update_blossom(state.ctx, blossom_id,
      best_edge: state.best_edge,
      best_edge_set: best_edge_set
    )
  end

  # Get the edge set to process for a sub-blossom
  defp get_sub_edge_set(state, %NonTrivial{best_edge_set: edge_set} = sub) when edge_set != nil do
    # Pull edge set from non-trivial sub-blossom and clear it
    ctx = Context.update_blossom(state.ctx, sub.id, best_edge_set: nil)
    {edge_set, %{state | ctx: ctx}}
  end

  defp get_sub_edge_set(state, %Trivial{base_vertex: v}) do
    # For trivial blossoms, use all adjacent edges
    edge_set = Map.fetch!(state.ctx.graph.adjacent_edges, v)
    {edge_set, state}
  end

  defp get_sub_edge_set(state, %NonTrivial{best_edge_set: nil} = sub) do
    # NonTrivial with nil best_edge_set - use all adjacent edges of base vertex
    edge_set = Map.fetch!(state.ctx.graph.adjacent_edges, sub.base_vertex)
    {edge_set, state}
  end

  # Process all edges from a sub-blossom's edge set
  defp process_sub_edges(state, blossom, edge_set) do
    Enum.reduce(edge_set, state, fn e, state ->
      {x, y, _w} = Enum.at(state.ctx.graph.edges, e)
      bx = Context.get_vertex_blossom(state.ctx, x)
      by = Context.get_vertex_blossom(state.ctx, y)

      # Skip edges internal to the new blossom
      if bx.id == by.id do
        state
      else
        # Determine which blossom is external
        other_blossom = if bx.id == blossom.id, do: by, else: bx

        # Skip edges that don't link to an S-blossom
        if other_blossom.label != :s do
          state
        else
          slack = Slack.edge_slack_2x(state.ctx, e)
          bx_base = other_blossom.base_vertex

          # Update best edge to this external blossom
          current_edge = Map.fetch!(state.best_edge_to_blossom, bx_base)
          current_slack = Map.fetch!(state.best_slack_to_blossom, bx_base)

          state =
            if current_edge == -1 or slack < current_slack do
              %{
                state
                | best_edge_to_blossom: Map.put(state.best_edge_to_blossom, bx_base, e),
                  best_slack_to_blossom: Map.put(state.best_slack_to_blossom, bx_base, slack)
              }
            else
              state
            end

          # Update overall best edge
          if state.best_edge == -1 or slack < state.best_slack do
            %{state | best_edge: e, best_slack: slack}
          else
            state
          end
        end
      end
    end)
  end
end
