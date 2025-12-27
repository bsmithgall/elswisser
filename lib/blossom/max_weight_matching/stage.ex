defmodule Blossom.MaxWeightMatching.Stage do
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

  alias Blossom.MaxWeightMatching.Context
  alias Blossom.MaxWeightMatching.LeastSlack
  alias Blossom.MaxWeightMatching.AlternatingPath

  alias Blossom.MaxWeightMatching.Blossom.NonTrivial

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
    # Trace back through the alternating trees from x and y
    {path, ctx} = AlternatingPath.trace_alternating_paths(ctx, x, y)

    # Check if the path is a cycle (starts and ends in same blossom)
    [{p, _} | _] = path.edges
    {_, q} = List.last(path.edges)

    if Context.same_blossom?(ctx, p, q) do
      # Path forms a cycle - a new blossom should be created (Phase 8)
      {:blossom, ctx}
    else
      # Path connects different trees - augmenting path found
      {:augmenting_path, path, ctx}
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
