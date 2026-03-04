defmodule TestSupport.Verification do
  @moduledoc """
  Verification functions for the maximum weight matching algorithm.

  These functions verify that a computed matching is optimal by checking
  the dual feasibility conditions from the linear programming formulation.

  Used internally for testing and debugging.
  """

  alias MaxWeightMatching.Context
  alias MaxWeightMatching.Graph
  alias MaxWeightMatching.Blossom.Trivial
  alias MaxWeightMatching.Blossom.NonTrivial
  alias MaxWeightMatching.Blossom

  @doc """
  Verifies that the computed matching is optimal.

  Checks the following conditions:
  1. Matched edges are symmetric (vertex_mate[x] == y iff vertex_mate[y] == x)
  2. Number of matched vertices equals 2 * number of matched edges
  3. All dual variables are non-negative
  4. Unmatched vertices have zero dual
  5. All edges have non-negative slack (after blossom adjustment)
  6. All matched edges have zero slack

  Returns `{:ok, :verified}` if all conditions pass, or `{:error, reason}` otherwise.

  Time complexity: O(n²)
  """
  @spec verify_optimum(Context.t()) :: {:ok, :verified} | {:error, String.t()}
  def verify_optimum(%Context{graph: %{num_vertex: 0}}) do
    {:ok, :verified}
  end

  def verify_optimum(%Context{} = ctx) do
    with :ok <- verify_matching_symmetry(ctx),
         :ok <- verify_matching_consistency(ctx),
         :ok <- verify_dual_non_negative(ctx),
         :ok <- verify_unmatched_zero_dual(ctx),
         {:ok, edge_slack_2x} <- compute_and_verify_edge_slacks(ctx) do
      verify_matched_edge_slacks(ctx, edge_slack_2x)
    end
  end

  # Step 1: Verify matched edges are symmetric
  defp verify_matching_symmetry(%Context{graph: graph, vertex_mate: vertex_mate}) do
    Enum.reduce_while(0..(graph.num_vertex - 1), :ok, fn x, :ok ->
      y = Map.fetch!(vertex_mate, x)

      cond do
        y == -1 ->
          {:cont, :ok}

        Map.fetch!(vertex_mate, y) != x ->
          {:halt, {:error, "asymmetric match of vertex #{x} and #{y}"}}

        true ->
          {:cont, :ok}
      end
    end)
  end

  # Step 2: Verify matched vertices count equals 2x matched edges
  defp verify_matching_consistency(%Context{graph: graph, vertex_mate: vertex_mate}) do
    num_matched_vertex =
      0..(graph.num_vertex - 1)
      |> Enum.count(fn x -> Map.fetch!(vertex_mate, x) != -1 end)

    num_matched_edge =
      graph.edges
      |> Map.values()
      |> Enum.count(fn {x, y, _w} -> Map.fetch!(vertex_mate, x) == y end)

    if num_matched_vertex == 2 * num_matched_edge do
      :ok
    else
      {:error,
       "#{num_matched_vertex} matched vertices inconsistent with #{num_matched_edge} matched edges"}
    end
  end

  # Step 3: Verify all dual variables are non-negative
  defp verify_dual_non_negative(%Context{
         graph: graph,
         vertex_dual_2x: vertex_dual_2x,
         blossoms: blossoms
       }) do
    # Check vertex duals
    vertex_result =
      Enum.reduce_while(0..(graph.num_vertex - 1), :ok, fn x, :ok ->
        dual = Map.fetch!(vertex_dual_2x, x)

        if dual < 0 do
          {:halt, {:error, "vertex #{x} has negative dual #{dual / 2}"}}
        else
          {:cont, :ok}
        end
      end)

    case vertex_result do
      :ok ->
        # Check blossom duals
        blossoms
        |> Enum.reduce_while(:ok, fn {_id, blossom}, :ok ->
          case blossom do
            %NonTrivial{dual_var_2x: dual_var_2x} when dual_var_2x < 0 ->
              {:halt, {:error, "negative blossom dual #{dual_var_2x}"}}

            _ ->
              {:cont, :ok}
          end
        end)

      error ->
        error
    end
  end

  # Step 4: Verify unmatched vertices have zero dual
  defp verify_unmatched_zero_dual(%Context{
         graph: graph,
         vertex_mate: vertex_mate,
         vertex_dual_2x: vertex_dual_2x
       }) do
    Enum.reduce_while(0..(graph.num_vertex - 1), :ok, fn x, :ok ->
      mate = Map.fetch!(vertex_mate, x)
      dual = Map.fetch!(vertex_dual_2x, x)

      if mate == -1 and dual != 0 do
        {:halt, {:error, "unmatched vertex #{x} has non-zero dual #{dual / 2}"}}
      else
        {:cont, :ok}
      end
    end)
  end

  # Step 5: Compute edge slacks, adjust for blossoms, and verify non-negative
  defp compute_and_verify_edge_slacks(
         %Context{graph: graph, vertex_dual_2x: vertex_dual_2x, blossoms: blossoms} = ctx
       ) do
    # Calculate initial slack for each edge
    edge_slack_2x =
      Map.new(graph.edges, fn {e, {x, y, w}} ->
        slack = Map.fetch!(vertex_dual_2x, x) + Map.fetch!(vertex_dual_2x, y) - 2 * w
        {e, slack}
      end)

    # Descend down each top-level non-trivial blossom to adjust slacks
    top_level_blossoms =
      blossoms
      |> Enum.filter(fn {_id, b} ->
        match?(%NonTrivial{parent_id: nil}, b)
      end)
      |> Enum.map(fn {_id, b} -> b end)

    result =
      Enum.reduce_while(top_level_blossoms, {:ok, edge_slack_2x}, fn blossom, {:ok, slack_map} ->
        case verify_blossom_edges(ctx, blossom, slack_map) do
          {:ok, updated_slack} -> {:cont, {:ok, updated_slack}}
          {:error, _} = error -> {:halt, error}
        end
      end)

    case result do
      {:ok, final_slack_2x} ->
        # Check all edges have non-negative slack
        min_slack = final_slack_2x |> Map.values() |> Enum.min(fn -> 0 end)

        if min_slack < 0 do
          {:error, "negative edge slack #{min_slack / 2}"}
        else
          {:ok, final_slack_2x}
        end

      error ->
        error
    end
  end

  # Step 6: Verify matched edges have zero slack
  defp verify_matched_edge_slacks(%Context{graph: graph, vertex_mate: vertex_mate}, edge_slack_2x) do
    result =
      Enum.reduce_while(graph.edges, :ok, fn {e, {x, y, _w}}, :ok ->
        if Map.fetch!(vertex_mate, x) == y do
          slack = Map.fetch!(edge_slack_2x, e)

          if slack != 0 do
            {:halt, {:error, "matched edge (#{x}, #{y}) has slack #{slack / 2}"}}
          else
            {:cont, :ok}
          end
        else
          {:cont, :ok}
        end
      end)

    case result do
      :ok -> {:ok, :verified}
      error -> error
    end
  end

  @doc """
  Descends down the blossom tree to adjust edge slacks and verify blossom fullness.

  For each blossom with non-zero dual, verifies that it is "full" - meaning all
  but one of its vertices are matched to another vertex within the blossom.

  Returns `{:ok, updated_edge_slack_2x}` or `{:error, reason}`.
  """
  @spec verify_blossom_edges(Context.t(), NonTrivial.t(), map()) ::
          {:ok, map()} | {:error, String.t()}
  def verify_blossom_edges(
        %Context{graph: graph, vertex_mate: vertex_mate, blossoms: blossoms},
        blossom,
        edge_slack_2x
      ) do
    num_vertex = graph.num_vertex

    # For each vertex, track the depth of the smallest blossom containing it
    initial_vertex_depth = Map.new(0..(num_vertex - 1), fn x -> {x, 0} end)

    # Use maps keyed by depth for clarity
    # path_sum_dual[depth] = sum of blossom duals from root to depth
    # path_num_matched[depth] = number of matched edges at depth
    initial_path_sum_dual = %{0 => 0}
    initial_path_num_matched = %{0 => 0}

    # Use explicit stack: {blossom, sub_index} where sub_index is -1 when first entering
    initial_stack = [{blossom, -1}]

    do_verify_blossom_edges(
      graph,
      vertex_mate,
      blossoms,
      initial_stack,
      initial_vertex_depth,
      initial_path_sum_dual,
      initial_path_num_matched,
      edge_slack_2x
    )
  end

  defp do_verify_blossom_edges(
         _graph,
         _vertex_mate,
         _blossoms,
         [],
         _vertex_depth,
         _path_sum_dual,
         _path_num_matched,
         edge_slack_2x
       ) do
    {:ok, edge_slack_2x}
  end

  defp do_verify_blossom_edges(
         graph,
         vertex_mate,
         blossoms,
         [{blossom, p} | rest_stack],
         vertex_depth,
         path_sum_dual,
         path_num_matched,
         edge_slack_2x
       ) do
    depth = length(rest_stack) + 1

    if p == -1 do
      # We just entered this sub-blossom
      # Update the depth of all vertices in this blossom
      blossom_vertices = Blossom.vertices(blossom.id, blossoms)

      updated_vertex_depth =
        Enum.reduce(blossom_vertices, vertex_depth, fn x, acc ->
          Map.put(acc, x, depth)
        end)

      # Calculate the sum of blossom duals at the current depth
      parent_sum = Map.fetch!(path_sum_dual, depth - 1)
      updated_path_sum_dual = Map.put(path_sum_dual, depth, parent_sum + blossom.dual_var_2x)

      # Initialize the number of matched edges at current depth
      updated_path_num_matched = Map.put(path_num_matched, depth, 0)

      # Continue with p = 0
      do_verify_blossom_edges(
        graph,
        vertex_mate,
        blossoms,
        [{blossom, 0} | rest_stack],
        updated_vertex_depth,
        updated_path_sum_dual,
        updated_path_num_matched,
        edge_slack_2x
      )
    else
      num_subblossoms = length(blossom.subblossom_ids)

      if p < num_subblossoms do
        # Get the sub-blossom at position p
        sub_id = Enum.at(blossom.subblossom_ids, p)
        sub = Map.fetch!(blossoms, sub_id)

        # Update stack to process next sub-blossom after this one
        updated_stack = [{blossom, p + 1} | rest_stack]

        case sub do
          %NonTrivial{} ->
            # Descend into non-trivial sub-blossom
            do_verify_blossom_edges(
              graph,
              vertex_mate,
              blossoms,
              [{sub, -1} | updated_stack],
              vertex_depth,
              path_sum_dual,
              path_num_matched,
              edge_slack_2x
            )

          %Trivial{base_vertex: base_v} ->
            # Handle trivial sub-blossom: scan its adjacent edges
            {updated_slack, updated_num_matched} =
              Enum.reduce(
                Map.fetch!(graph.adjacent_edges, base_v),
                {edge_slack_2x, path_num_matched},
                fn e, {slack_acc, matched_acc} ->
                  {x, y, _w} = Graph.get_edge(graph, e)

                  # Only process edges ordered out from this sub-blossom
                  if x == base_v do
                    edge_depth = Map.fetch!(vertex_depth, y)

                    if edge_depth > 0 do
                      # This edge is contained in an ancestor blossom
                      # Update its slack using path_sum_dual at edge_depth
                      path_sum_at_depth = Map.fetch!(path_sum_dual, edge_depth)
                      new_slack = Map.fetch!(slack_acc, e) + 2 * path_sum_at_depth
                      updated_slack_map = Map.put(slack_acc, e, new_slack)

                      # Update matched edges count at edge_depth
                      if Map.fetch!(vertex_mate, x) == y do
                        updated_matched_map = Map.update!(matched_acc, edge_depth, &(&1 + 1))
                        {updated_slack_map, updated_matched_map}
                      else
                        {updated_slack_map, matched_acc}
                      end
                    else
                      {slack_acc, matched_acc}
                    end
                  else
                    {slack_acc, matched_acc}
                  end
                end
              )

            do_verify_blossom_edges(
              graph,
              vertex_mate,
              blossoms,
              updated_stack,
              vertex_depth,
              path_sum_dual,
              updated_num_matched,
              updated_slack
            )
        end
      else
        # We are now leaving the current sub-blossom
        blossom_vertices = Blossom.vertices(blossom.id, blossoms)
        blossom_num_vertex = length(blossom_vertices)

        # Get number of matched edges at current depth
        blossom_num_matched = Map.fetch!(path_num_matched, depth)

        # Check that blossom is "full" (all but one vertex matched internally)
        # Only check if dual_var_2x != 0
        if blossom.dual_var_2x != 0 and blossom_num_vertex != 2 * blossom_num_matched + 1 do
          {:error,
           "blossom non-full dual=#{blossom.dual_var_2x} nvertex=#{blossom_num_vertex} nmatched=#{blossom_num_matched}"}
        else
          # Update matched edges count in parent blossom
          updated_path_num_matched =
            Map.update!(path_num_matched, depth - 1, &(&1 + Map.fetch!(path_num_matched, depth)))

          # Revert depth of vertices in this blossom
          updated_vertex_depth =
            Enum.reduce(blossom_vertices, vertex_depth, fn x, acc ->
              Map.put(acc, x, depth - 1)
            end)

          do_verify_blossom_edges(
            graph,
            vertex_mate,
            blossoms,
            rest_stack,
            updated_vertex_depth,
            path_sum_dual,
            updated_path_num_matched,
            edge_slack_2x
          )
        end
      end
    end
  end
end
