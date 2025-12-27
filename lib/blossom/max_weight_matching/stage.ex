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
      if e3 != -1 do
        if ctx.graph.integer_weights do
          div(slack3_raw, 2)
        else
          slack3_raw / 2
        end
      else
        slack3_raw
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

  # --- Private Helper Functions ---

  # Calculate delta1: minimum dual variable of any S-vertex
  defp calc_delta1(%Context{} = ctx) do
    0..(ctx.graph.num_vertex - 1)
    |> Enum.reduce(nil, fn x, min_dual ->
      blossom = Context.get_vertex_blossom(ctx, x)

      if blossom.label == :s do
        dual = Map.fetch!(ctx.vertex_dual_2x, x)

        if is_nil(min_dual) or dual < min_dual do
          dual
        else
          min_dual
        end
      else
        min_dual
      end
    end)
  end

  # Calculate delta4: minimum dual_var of any top-level T-blossom
  # Returns {min_dual_var, blossom_id} or {nil, nil} if no T-blossoms
  defp calc_delta4(%Context{} = ctx) do
    ctx.blossoms
    |> Map.values()
    |> Enum.reduce({nil, nil}, fn blossom, {min_dual, min_id} ->
      case blossom do
        %NonTrivial{label: :t, parent_id: nil, dual_var: dual_var, id: id} ->
          if is_nil(min_dual) or dual_var < min_dual do
            {dual_var, id}
          else
            {min_dual, min_id}
          end

        _ ->
          {min_dual, min_id}
      end
    end)
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

  # Update vertex duals based on labels
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

  # Update blossom duals for top-level non-trivial blossoms
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
