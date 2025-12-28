defmodule Blossom.MaxWeightMatchingTest do
  @moduledoc """
  End-to-end tests for the maximum weight matching algorithm.

  These tests verify the complete algorithm behavior on various graph types.
  Phase 7 focuses on bipartite graphs (no odd cycles).
  """

  use ExUnit.Case, async: true

  alias Blossom.MaxWeightMatching

  # Helper to calculate total weight of a matching
  defp total_weight(edges, matching) do
    matching
    |> Enum.map(fn {x, y} ->
      Enum.find_value(edges, 0, fn {a, b, w} ->
        if (a == x and b == y) or (a == y and b == x), do: w
      end)
    end)
    |> Enum.sum()
  end

  # Helper to verify matching is valid (no vertex appears twice)
  defp valid_matching?(matching) do
    vertices = Enum.flat_map(matching, fn {x, y} -> [x, y] end)
    length(vertices) == length(Enum.uniq(vertices))
  end

  describe "basic cases" do
    test "empty graph returns empty matching" do
      assert MaxWeightMatching.maximum_weight_matching([]) == []
    end

    test "single edge returns that edge" do
      #     5
      # (0)----(1)
      #
      # Result: match 0-1
      result = MaxWeightMatching.maximum_weight_matching([{0, 1, 5}])
      assert result == [{0, 1}]
    end

    test "single edge with different vertices" do
      result = MaxWeightMatching.maximum_weight_matching([{2, 7, 10}])
      assert result == [{2, 7}]
    end

    test "path graph - heavier edge wins" do
      #     5       3
      # (0)----(1)----(2)
      #
      # Can only match one edge (vertex 1 is shared)
      # Optimal: match 0-1 (weight 5) over 1-2 (weight 3)
      edges = [{0, 1, 5}, {1, 2, 3}]
      result = MaxWeightMatching.maximum_weight_matching(edges)

      assert length(result) == 1
      assert total_weight(edges, result) == 5
    end

    test "path graph with equal weights" do
      #     10      10
      # (0)----(1)----(2)
      #
      # Either edge gives same weight, picks one
      edges = [{0, 1, 10}, {1, 2, 10}]
      result = MaxWeightMatching.maximum_weight_matching(edges)

      assert length(result) == 1
      assert total_weight(edges, result) == 10
    end
  end

  describe "bipartite graphs (Phase 7 milestone)" do
    test "square (4-cycle) - perfect matching" do
      # (0)----(1)
      #  |      |
      #  |      |
      # (3)----(2)
      #
      # All edges weight 1. Perfect matching uses 2 non-adjacent edges.
      # Result: either {0-1, 2-3} or {0-3, 1-2}
      edges = [{0, 1, 1}, {1, 2, 1}, {2, 3, 1}, {3, 0, 1}]
      result = MaxWeightMatching.maximum_weight_matching(edges)

      assert valid_matching?(result)
      assert length(result) == 2
      assert total_weight(edges, result) == 2
    end

    test "6-cycle - perfect matching" do
      #       (1)
      #      /   \
      #    (0)   (2)
      #     |     |
      #    (5)   (3)
      #      \   /
      #       (4)
      #
      # Hexagon with all edges weight 1.
      # Perfect matching uses 3 non-adjacent edges.
      edges = [
        {0, 1, 1},
        {1, 2, 1},
        {2, 3, 1},
        {3, 4, 1},
        {4, 5, 1},
        {5, 0, 1}
      ]

      result = MaxWeightMatching.maximum_weight_matching(edges)

      assert valid_matching?(result)
      assert length(result) == 3
      assert total_weight(edges, result) == 3
    end

    test "complete bipartite K2,2" do
      # Left     Right
      # (0)------(2)
      #   \    /
      #    \  /
      #     \/
      #     /\
      #    /  \
      #   /    \
      # (1)------(3)
      #
      # Complete bipartite: every left vertex connects to every right vertex.
      # Perfect matching uses 2 edges (one per left vertex).
      edges = [
        {0, 2, 1},
        {0, 3, 1},
        {1, 2, 1},
        {1, 3, 1}
      ]

      result = MaxWeightMatching.maximum_weight_matching(edges)

      assert valid_matching?(result)
      assert length(result) == 2
    end

    test "complete bipartite K3,3" do
      # Left      Right
      # (0)-------(3)
      # (1)-------(4)
      # (2)-------(5)
      #   (all 9 edges connecting left to right)
      #
      # Perfect matching uses 3 edges.
      edges =
        for i <- 0..2, j <- 3..5 do
          {i, j, 1}
        end

      result = MaxWeightMatching.maximum_weight_matching(edges)

      assert valid_matching?(result)
      assert length(result) == 3
    end

    test "path of length 4 vertices" do
      #     1       1       1
      # (0)----(1)----(2)----(3)
      #
      # Maximum matching: 2 edges (e.g., 0-1 and 2-3)
      edges = [{0, 1, 1}, {1, 2, 1}, {2, 3, 1}]
      result = MaxWeightMatching.maximum_weight_matching(edges)

      assert valid_matching?(result)
      assert length(result) == 2
    end

    test "path of length 5 vertices" do
      #     1       1       1       1
      # (0)----(1)----(2)----(3)----(4)
      #
      # Maximum matching: 2 edges (must skip middle vertex)
      # Either {0-1, 2-3} or {0-1, 3-4} or {1-2, 3-4}
      edges = [{0, 1, 1}, {1, 2, 1}, {2, 3, 1}, {3, 4, 1}]
      result = MaxWeightMatching.maximum_weight_matching(edges)

      assert valid_matching?(result)
      assert length(result) == 2
    end
  end

  describe "weight optimization" do
    test "prefers heavier edges" do
      #    10           5
      # (0)----(1)   (2)----(3)
      #
      # Two independent edges, both can be matched.
      # Total weight: 15
      edges = [{0, 1, 10}, {2, 3, 5}]
      result = MaxWeightMatching.maximum_weight_matching(edges)

      assert valid_matching?(result)
      assert length(result) == 2
      assert total_weight(edges, result) == 15
    end

    test "chooses optimal matching over maximal - simple case" do
      #     10      1
      # (0)====(1)----(2)
      #
      # Greedy might pick 1-2 first, but optimal is 0-1 only.
      # Weight 10 > weight 1, even though 1 edge < 2 edges possible.
      edges = [{0, 1, 10}, {1, 2, 1}]
      result = MaxWeightMatching.maximum_weight_matching(edges)

      assert [{0, 1}] = result
      assert total_weight(edges, result) == 10
    end

    test "chooses optimal matching in 4-cycle with unequal weights" do
      #       10
      # (0)========(1)
      #  |          |
      #  | 1      1 |
      #  |          |
      # (3)========(2)
      #       10
      #
      # Optimal: match horizontal edges (0-1, 2-3) for weight 20
      # Suboptimal: match vertical edges (0-3, 1-2) for weight 2
      edges = [{0, 1, 10}, {1, 2, 1}, {2, 3, 10}, {3, 0, 1}]
      result = MaxWeightMatching.maximum_weight_matching(edges)

      assert valid_matching?(result)
      assert length(result) == 2
      assert total_weight(edges, result) == 20
    end

    test "star graph - matches one edge" do
      #        (1)
      #         |  5
      #         |
      # (2)--3--(0)--7--(3)
      #
      # Center vertex 0 can only be matched once.
      # Optimal: match 0-3 (weight 7)
      edges = [{0, 1, 5}, {0, 2, 3}, {0, 3, 7}]
      result = MaxWeightMatching.maximum_weight_matching(edges)

      assert valid_matching?(result)
      assert length(result) == 1
      assert total_weight(edges, result) == 7
    end
  end

  describe "disconnected graphs" do
    test "two independent edges" do
      #     5            10
      # (0)----(1)    (2)----(3)
      #
      # Two separate components, both edges matched.
      edges = [{0, 1, 5}, {2, 3, 10}]
      result = MaxWeightMatching.maximum_weight_matching(edges)

      assert valid_matching?(result)
      assert length(result) == 2
      assert total_weight(edges, result) == 15
    end

    test "two independent paths" do
      # Component 1:       Component 2:
      #     5       3          10
      # (0)----(1)----(2)   (3)----(4)
      #
      # Optimal: match 0-1 from path (weight 5) and 3-4 (weight 10)
      edges = [{0, 1, 5}, {1, 2, 3}, {3, 4, 10}]
      result = MaxWeightMatching.maximum_weight_matching(edges)

      assert valid_matching?(result)
      assert length(result) == 2
      assert total_weight(edges, result) == 15
    end
  end

  describe "edge cases" do
    test "negative weight edges are ignored" do
      #    -5       10
      # (0)~~~~(1)====(2)
      #  ignored   matched
      #
      # Negative weight edges are filtered out before matching.
      edges = [{0, 1, -5}, {1, 2, 10}]
      result = MaxWeightMatching.maximum_weight_matching(edges)

      assert [{1, 2}] = result
    end

    test "zero weight edge is valid" do
      #     0
      # (0)----(1)
      #
      # Zero weight is valid (not negative).
      result = MaxWeightMatching.maximum_weight_matching([{0, 1, 0}])
      assert result == [{0, 1}]
    end

    test "float weights work" do
      #    1.5      2.5
      # (0)----(1)====(2)
      #
      # Float weights work correctly. Optimal: match 1-2 (weight 2.5)
      edges = [{0, 1, 1.5}, {1, 2, 2.5}]
      result = MaxWeightMatching.maximum_weight_matching(edges)

      assert length(result) == 1
      assert total_weight(edges, result) == 2.5
    end
  end
end
