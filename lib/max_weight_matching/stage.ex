defmodule MaxWeightMatching.Stage do
  @moduledoc """
  Stage execution and dual variable updates for the blossom algorithm.

  A "stage" in the blossom algorithm searches for a maximum-weight augmenting
  path starting from unmatched vertices. Each stage consists of multiple
  "substages" that grow alternating trees and adjust dual variables.

  This module provides the core delta mechanics:
  - `reset_stage/1` - Reset state at the start of each stage
  - `substage_calc_dual_delta/1` - Calculate the next delta step
  - `substage_apply_delta_step/2` - Apply delta to dual variables
  """

  alias MaxWeightMatching.Context
  alias MaxWeightMatching.Graph
  alias MaxWeightMatching.LeastSlack
  alias MaxWeightMatching.AlternatingPath
  alias MaxWeightMatching.Slack
  alias MaxWeightMatching.Label
  alias MaxWeightMatching.Augment
  alias MaxWeightMatching.BlossomOps

  alias MaxWeightMatching.Blossom.NonTrivial

  @doc """
  Reset data which are only valid during a stage.

  Marks all blossoms as unlabeled, clears the queue, and resets tracking
  of least-slack edges.

  Called at the start of each stage before labeling unmatched vertices.

  ## Parameters

  - `ctx` - The current matching context

  ## Returns

  A new context with all stage-specific data reset.
  """
  @spec reset_stage(Context.t()) :: Context.t()
  def reset_stage(%Context{} = ctx) do
    blossoms =
      Map.new(ctx.blossoms, fn {id, blossom} ->
        {id, struct(blossom, label: :none, tree_edge: nil)}
      end)

    %{ctx | blossoms: blossoms}
    |> Context.clear_queue()
    |> LeastSlack.reset()
  end

  @doc """
  Calculate a delta step in the dual LPP problem.

  This function returns the minimum of the 4 types of delta values, the type
  of delta which obtains the minimum, and the edge or blossom that produces
  the minimum delta, if applicable.

  The returned delta value is 2 times the actual delta value. Multiplication
  by 2 ensures that the result is an integer if all edge weights are integers.

  ## Delta Types

  | Type | Source | Description |
  |------|--------|-------------|
  | 1 | S-vertex dual | Minimum dual of any S-vertex |
  | 2 | S-to-unlabeled edge | Minimum slack to unlabeled vertex |
  | 3 | S-to-S edge | Half minimum slack between S-blossoms |
  | 4 | T-blossom dual | Minimum dual of top-level T-blossom |

  On ties, higher-numbered delta types are preferred (matching Python reference).

  ## Preconditions

  - There is at least one S-vertex (algorithm must have started a stage)

  ## Parameters

  - `ctx` - The current matching context

  ## Returns

  Tuple `{delta_type, delta_2x, delta_edge, delta_blossom_id}` where:
  - `delta_type` - Integer 1-4 indicating which delta was minimum
  - `delta_2x` - The 2x delta value
  - `delta_edge` - Edge index for delta2/delta3, or -1
  - `delta_blossom_id` - Blossom ID for delta4, or nil
  """
  @spec substage_calc_dual_delta(Context.t()) ::
          {1..4, number(), integer(), reference() | nil}
  def substage_calc_dual_delta(%Context{} = ctx) do
    delta1 = calc_delta1(ctx)
    {e2, slack2} = LeastSlack.get_best_vertex_edge(ctx)
    {e3, slack3_raw} = LeastSlack.get_best_blossom_edge(ctx)

    slack3 =
      cond do
        e3 == -1 -> slack3_raw
        ctx.graph.integer_weights -> div(slack3_raw, 2)
        true -> slack3_raw / 2
      end

    {delta4, blossom4_id} = calc_delta4(ctx)

    find_minimum_delta(delta1, {e2, slack2}, {e3, slack3}, {delta4, blossom4_id})
  end

  @doc """
  Apply a delta step to the dual LPP variables.

  Updates dual variables for all vertices and top-level non-trivial blossoms
  based on their labels:
  - S-vertices: subtract delta from dual
  - T-vertices: add delta to dual
  - S-blossoms: add delta to dual_var (2*delta in actual terms)
  - T-blossoms: subtract delta from dual_var

  ## Parameters

  - `ctx` - The current matching context
  - `delta_2x` - The 2x delta value to apply

  ## Returns

  A new context with updated dual variables.
  """
  @spec substage_apply_delta_step(Context.t(), number()) :: Context.t()
  def substage_apply_delta_step(%Context{} = ctx, delta_2x) do
    %{
      ctx
      | vertex_dual_2x: update_vertex_duals(ctx, delta_2x),
        blossoms: update_blossom_duals(ctx, delta_2x)
    }
  end

  @doc """
  Add the edge between S-vertices `x` and `y`.

  If the edge connects blossoms that are part of the same alternating tree,
  a new S-blossom should be created (handled by Phase 8).

  If the edge connects two different alternating trees, an augmenting path
  has been discovered.

  ## Parameters

  - `ctx` - The current matching context
  - `x` - First S-vertex
  - `y` - Second S-vertex

  ## Returns

  - `{:augmenting_path, path, ctx}` if an augmenting path was found
  - `{:blossom, ctx}` if a blossom cycle was detected (blossom creation
    will be implemented in Phase 8)
  """
  @spec add_s_to_s_edge(Context.t(), non_neg_integer(), non_neg_integer()) ::
          {:augmenting_path, AlternatingPath.t(), Context.t()} | {:blossom, Context.t()}
  def add_s_to_s_edge(%Context{} = ctx, x, y) do
    {path, ctx} = AlternatingPath.trace_alternating_paths(ctx, x, y)

    [{p, _} | _] = path.edges
    {_, q} = List.last(path.edges)
    is_cycle = Context.same_blossom?(ctx, p, q)

    cond do
      not is_cycle ->
        {:augmenting_path, path, ctx}

      length(path.edges) >= 3 ->
        ctx = BlossomOps.make_blossom(ctx, path)
        {:blossom, ctx}

      true ->
        # Short cycle (< 3 edges) means vertices already in same blossom
        {:blossom, ctx}
    end
  end

  @doc """
  Scan queued S-vertices to expand the alternating trees.

  The scan proceeds until either an augmenting path is found,
  or the queue of S-vertices becomes empty.

  New blossoms may be created during the scan (handled in Phase 8).

  ## Parameters

  - `ctx` - The current matching context

  ## Returns

  - `{:augmenting_path, path, ctx}` if an augmenting path was found
  - `{nil, ctx}` if the queue was exhausted with no augmenting path
  """
  @spec substage_scan(Context.t()) ::
          {:augmenting_path, AlternatingPath.t(), Context.t()} | {nil, Context.t()}
  def substage_scan(%Context{} = ctx) do
    do_substage_scan(ctx)
  end

  defp do_substage_scan(%Context{} = ctx) do
    case Context.dequeue(ctx) do
      :empty ->
        {nil, ctx}

      {x, ctx} ->
        case scan_vertex_edges(ctx, x) do
          {:augmenting_path, path, ctx} -> {:augmenting_path, path, ctx}
          {:continue, ctx} -> do_substage_scan(ctx)
        end
    end
  end

  defp scan_vertex_edges(%Context{} = ctx, x) do
    adjacent_edges = Map.fetch!(ctx.graph.adjacent_edges, x)

    Enum.reduce_while(adjacent_edges, {:continue, ctx}, fn e, {:continue, ctx} ->
      {p, q, _w} = Graph.get_edge(ctx.graph, e)
      y = if p == x, do: q, else: p

      # Blossom membership may change during iteration, so refresh for each edge
      bx = Context.get_vertex_blossom(ctx, x)
      by = Context.get_vertex_blossom(ctx, y)

      if Context.same_blossom?(ctx, x, y) do
        {:cont, {:continue, ctx}}
      else
        case process_edge(ctx, x, y, e, bx, by) do
          {:augmenting_path, path, ctx} -> {:halt, {:augmenting_path, path, ctx}}
          ctx -> {:cont, {:continue, ctx}}
        end
      end
    end)
  end

  defp process_edge(ctx, x, y, e, bx, by) do
    slack = Slack.edge_slack_2x(ctx, e)
    {ctx, result} = handle_edge_by_slack(ctx, x, y, e, bx.id, by.label, slack)
    maybe_track_vertex_edge(ctx, result, y, e, by.label, slack)
  end

  # Tight edge to unlabeled blossom: assign T label
  defp handle_edge_by_slack(ctx, x, y, _e, _bx_id, :none, slack) when slack <= 0 do
    {Label.assign_label_t(ctx, x, y), :continue}
  end

  # Tight edge to S-blossom: may find augmenting path or create blossom
  defp handle_edge_by_slack(ctx, x, y, _e, _bx_id, :s, slack) when slack <= 0 do
    case add_s_to_s_edge(ctx, x, y) do
      {:augmenting_path, path, ctx} -> {ctx, {:augmenting_path, path}}
      {:blossom, ctx} -> {ctx, :continue}
    end
  end

  # Tight edge to T-blossom: no action needed
  defp handle_edge_by_slack(ctx, _x, _y, _e, _bx_id, :t, slack) when slack <= 0 do
    {ctx, :continue}
  end

  # Non-tight edge to S-blossom: track for delta3 calculation
  defp handle_edge_by_slack(ctx, _x, _y, e, bx_id, :s, slack) do
    {LeastSlack.add_blossom_edge(ctx, bx_id, e, slack), :continue}
  end

  # Non-tight edge to non-S blossom: no action in this phase
  defp handle_edge_by_slack(ctx, _x, _y, _e, _bx_id, _label, _slack) do
    {ctx, :continue}
  end

  # Found augmenting path - return immediately
  defp maybe_track_vertex_edge(ctx, {:augmenting_path, path}, _y, _e, _label, _slack) do
    {:augmenting_path, path, ctx}
  end

  # Track least-slack edges from non-S vertices for delta2 calculations
  defp maybe_track_vertex_edge(ctx, :continue, y, e, label, slack) when label != :s do
    LeastSlack.add_vertex_edge(ctx, y, e, slack)
  end

  # S-vertices don't need vertex edge tracking
  defp maybe_track_vertex_edge(ctx, :continue, _y, _e, :s, _slack) do
    ctx
  end

  @doc """
  Run one stage of the matching algorithm.

  The stage searches for a maximum-weight augmenting path.
  If this path is found, it is used to augment the matching,
  thereby increasing the number of matched edges by 1.
  If no such path is found, the matching must already be optimal.

  Time: O(n^2)

  ## Parameters

  - `ctx` - The current matching context

  ## Returns

  - `{true, ctx}` if the matching was successfully augmented
  - `{false, ctx}` if no further improvement is possible
  """
  @spec run_stage(Context.t()) :: {boolean(), Context.t()}
  def run_stage(%Context{} = ctx) do
    ctx =
      Enum.reduce(0..(ctx.graph.num_vertex - 1), ctx, fn x, ctx ->
        if Map.fetch!(ctx.vertex_mate, x) == -1 do
          Label.assign_label_s(ctx, x)
        else
          ctx
        end
      end)

    if Context.queue_empty?(ctx) do
      {false, ctx}
    else
      {augmenting_path, ctx} = run_substages(ctx)

      ctx =
        case augmenting_path do
          nil -> ctx
          path -> Augment.augment_matching(ctx, path)
        end

      ctx = reset_stage(ctx)
      {augmenting_path != nil, ctx}
    end
  end

  defp run_substages(%Context{} = ctx) do
    case substage_scan(ctx) do
      {:augmenting_path, path, ctx} ->
        {path, ctx}

      {nil, ctx} ->
        {delta_type, delta_2x, delta_edge, delta_blossom_id} = substage_calc_dual_delta(ctx)
        ctx = substage_apply_delta_step(ctx, delta_2x)

        case delta_type do
          1 ->
            # Minimum dual is zero; no further improvement possible
            {nil, ctx}

          2 ->
            # S-to-unlabeled edge became tight
            {x, y, _w} = Graph.get_edge(ctx.graph, delta_edge)
            {x, y} = if Context.get_vertex_blossom(ctx, x).label != :s, do: {y, x}, else: {x, y}
            ctx = Label.assign_label_t(ctx, x, y)
            run_substages(ctx)

          3 ->
            # S-to-S edge became tight
            {x, y, _w} = Graph.get_edge(ctx.graph, delta_edge)

            case add_s_to_s_edge(ctx, x, y) do
              {:augmenting_path, path, ctx} -> {path, ctx}
              {:blossom, ctx} -> run_substages(ctx)
            end

          4 ->
            # T-blossom dual reached zero, expand it
            ctx = BlossomOps.expand_t_blossom(ctx, delta_blossom_id)
            run_substages(ctx)
        end
    end
  end

  defp calc_delta1(%Context{} = ctx) do
    0..(ctx.graph.num_vertex - 1)
    |> Enum.filter(fn x -> Context.get_vertex_blossom(ctx, x).label == :s end)
    |> Enum.map(fn x -> Map.fetch!(ctx.vertex_dual_2x, x) end)
    |> Enum.min(fn -> nil end)
  end

  defp calc_delta4(%Context{} = ctx) do
    ctx.blossoms
    |> Map.values()
    |> Enum.filter(fn
      %NonTrivial{label: :t, parent_id: nil} -> true
      _ -> false
    end)
    |> Enum.min_by(& &1.dual_var, fn -> nil end)
    |> case do
      nil -> {nil, nil}
      blossom -> {blossom.dual_var, blossom.id}
    end
  end

  defp find_minimum_delta(delta1, {e2, slack2}, {e3, slack3}, {delta4, blossom4_id}) do
    # Start with delta1 (always exists if there's an S-vertex)
    {1, delta1, -1, nil}
    |> maybe_replace_delta(2, e2, slack2)
    |> maybe_replace_delta(3, e3, slack3)
    |> maybe_replace_delta_blossom(delta4, blossom4_id)
  end

  defp maybe_replace_delta(current, _type, -1, _slack), do: current

  defp maybe_replace_delta({_, current_delta, _, _} = current, type, edge, slack) do
    if slack <= current_delta, do: {type, slack, edge, nil}, else: current
  end

  defp maybe_replace_delta_blossom(current, nil, _blossom_id), do: current

  defp maybe_replace_delta_blossom({_, current_delta, _, _} = current, delta, blossom_id) do
    if delta <= current_delta, do: {4, delta, -1, blossom_id}, else: current
  end

  defp update_vertex_duals(%Context{} = ctx, delta_2x) do
    Map.new(0..(ctx.graph.num_vertex - 1), fn x ->
      blossom = Context.get_vertex_blossom(ctx, x)
      current_dual = Map.fetch!(ctx.vertex_dual_2x, x)

      new_dual =
        case blossom.label do
          :s -> current_dual - delta_2x
          :t -> current_dual + delta_2x
          :none -> current_dual
        end

      {x, new_dual}
    end)
  end

  defp update_blossom_duals(%Context{} = ctx, delta_2x) do
    Map.new(ctx.blossoms, fn {id, blossom} ->
      updated =
        case blossom do
          %NonTrivial{parent_id: nil, label: :s, dual_var: dual_var} ->
            # S-blossom: add delta to dual_var
            %{blossom | dual_var: dual_var + delta_2x}

          %NonTrivial{parent_id: nil, label: :t, dual_var: dual_var} ->
            # T-blossom: subtract delta from dual_var
            %{blossom | dual_var: dual_var - delta_2x}

          _ ->
            # Trivial blossoms, nested blossoms, or unlabeled: no change
            blossom
        end

      {id, updated}
    end)
  end
end
