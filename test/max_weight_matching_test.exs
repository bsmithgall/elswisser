defmodule MaxWeightMatchingTest do
  @moduledoc """
  End-to-end tests for the maximum weight matching algorithm.

  These tests verify the complete algorithm behavior on various graph types.
  Phase 7 focuses on bipartite graphs (no odd cycles).
  """

  use ExUnit.Case, async: true

  alias MaxWeightMatching

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

  describe "odd cycles (Phase 8 - blossom creation)" do
    test "triangle - matches one edge" do
      #      10
      #   (0)----(1)
      #    \    /
      #  10 \  / 10
      #      \/
      #     (2)
      #
      # Triangle requires blossom to be formed.
      # Only one edge can be matched (other vertex left unmatched).
      edges = [{0, 1, 10}, {1, 2, 10}, {0, 2, 10}]
      result = MaxWeightMatching.maximum_weight_matching(edges)

      assert valid_matching?(result)
      assert length(result) == 1
      assert total_weight(edges, result) == 10
    end

    test "triangle with different weights" do
      #      10
      #   (0)====(1)
      #    \    /
      #   5 \  / 5
      #      \/
      #     (2)
      #
      # The heavier edge (0-1) should be chosen.
      edges = [{0, 1, 10}, {1, 2, 5}, {0, 2, 5}]
      result = MaxWeightMatching.maximum_weight_matching(edges)

      assert valid_matching?(result)
      assert length(result) == 1
      assert total_weight(edges, result) == 10
    end

    test "pentagon (5-cycle) - matches two edges" do
      #       (1)
      #      /   \
      #    (0)   (2)
      #     |     |
      #    (4)---(3)
      #
      # Pentagon (odd cycle) with all edges weight 1.
      # Maximum matching: 2 edges (one vertex unmatched).
      edges = [{0, 1, 1}, {1, 2, 1}, {2, 3, 1}, {3, 4, 1}, {4, 0, 1}]
      result = MaxWeightMatching.maximum_weight_matching(edges)

      assert valid_matching?(result)
      assert length(result) == 2
      assert total_weight(edges, result) == 2
    end

    test "triangle with tail" do
      #     5       5
      #  (0)----(1)----(2)
      #           \    /
      #          5 \  /
      #             \/
      #  (3)========(2)
      #       10
      #
      # Triangle 1-2-0 plus edge 2-3.
      # If we match inside triangle: weight 5
      # If we match 2-3 (weight 10) and 0-1 (weight 5): weight 15
      # Optimal: match {0,1} and {2,3} for weight 15
      edges = [{0, 1, 5}, {1, 2, 5}, {0, 2, 5}, {2, 3, 10}]
      result = MaxWeightMatching.maximum_weight_matching(edges)

      assert valid_matching?(result)
      assert total_weight(edges, result) == 15
    end

    test "two triangles sharing edge" do
      #     (1)       (3)
      #    /   \     /   \
      #  (0)====(2)====(4)
      #
      # Two triangles sharing vertex 2.
      # Vertices: 0,1,2 form one triangle; 2,3,4 form another.
      # Maximum matching: 2 edges from the opposite ends.
      edges = [
        {0, 1, 1},
        {1, 2, 1},
        {0, 2, 1},
        {2, 3, 1},
        {3, 4, 1},
        {2, 4, 1}
      ]

      result = MaxWeightMatching.maximum_weight_matching(edges)

      assert valid_matching?(result)
      assert length(result) == 2
    end

    test "7-cycle" do
      # Odd cycle of length 7.
      # Maximum matching: 3 edges (one vertex unmatched).
      edges =
        for i <- 0..6 do
          {i, rem(i + 1, 7), 1}
        end

      result = MaxWeightMatching.maximum_weight_matching(edges)

      assert valid_matching?(result)
      assert length(result) == 3
      assert total_weight(edges, result) == 3
    end

    test "complete graph K4" do
      # Complete graph on 4 vertices.
      # All edges weight 1.
      # Maximum matching: 2 edges (perfect matching exists).
      edges = [
        {0, 1, 1},
        {0, 2, 1},
        {0, 3, 1},
        {1, 2, 1},
        {1, 3, 1},
        {2, 3, 1}
      ]

      result = MaxWeightMatching.maximum_weight_matching(edges)

      assert valid_matching?(result)
      assert length(result) == 2
      assert total_weight(edges, result) == 2
    end

    test "triangle connected to path" do
      #     5       5       5
      #  (0)----(1)----(2)----(3)
      #          |     /
      #        5 |    / 5
      #          |   /
      #          (4)
      #
      # Triangle 1-2-4 with paths extending to 0 and 3.
      # Maximum matching should be 2 edges for weight 10.
      edges = [
        {0, 1, 5},
        {1, 2, 5},
        {2, 3, 5},
        {1, 4, 5},
        {2, 4, 5}
      ]

      result = MaxWeightMatching.maximum_weight_matching(edges)

      assert valid_matching?(result)
      assert length(result) == 2
    end
  end

  describe "blossom expansion (Phase 9)" do
    test "augmenting path through blossom" do
      # A triangle connected to external vertices that require augmentation
      # through the blossom.
      #
      #      (3)
      #       |  10
      #      (0)----(1)
      #        \    /
      #      5  \  / 5
      #          \/
      #         (2)
      #          |  10
      #         (4)
      #
      # Triangle 0-1-2 with external edges to 3 and 4.
      # The augmenting path 3-0-...-2-4 goes through the blossom.
      edges = [
        {0, 1, 5},
        {1, 2, 5},
        {0, 2, 5},
        {0, 3, 10},
        {2, 4, 10}
      ]

      result = MaxWeightMatching.maximum_weight_matching(edges)

      assert valid_matching?(result)
      # Optimal: match 3-0 and 4-2, leaving 1 unmatched
      assert total_weight(edges, result) == 20
    end

    test "nested blossoms - two triangles connected" do
      # Two triangles connected by an edge, creating opportunity for nested
      # blossom structures.
      #
      #     (1)         (4)
      #    /   \       /   \
      #  (0)----(2)---(3)----(5)
      #
      # Triangle 0-1-2 and triangle 3-4-5 connected by edge 2-3.
      edges = [
        {0, 1, 1},
        {1, 2, 1},
        {0, 2, 1},
        {2, 3, 1},
        {3, 4, 1},
        {4, 5, 1},
        {3, 5, 1}
      ]

      result = MaxWeightMatching.maximum_weight_matching(edges)

      assert valid_matching?(result)
      # Maximum matching: 3 edges
      assert length(result) == 3
    end

    test "nested blossom with external matching" do
      # A blossom that needs to be expanded during augmentation.
      #
      #         (1)
      #        / | \
      #      (0)-+-(2)
      #        \ | /
      #         (3)----(4)
      #
      # Complete graph K4 on vertices 0-3, plus edge to 4.
      # This requires blossom creation and expansion.
      edges = [
        {0, 1, 1},
        {0, 2, 1},
        {0, 3, 1},
        {1, 2, 1},
        {1, 3, 1},
        {2, 3, 1},
        {3, 4, 10}
      ]

      result = MaxWeightMatching.maximum_weight_matching(edges)

      assert valid_matching?(result)
      # Optimal: match 3-4 (weight 10) and one edge from remaining triangle
      assert total_weight(edges, result) == 11
    end

    test "complex graph with multiple blossoms" do
      # Two triangles sharing a vertex, with external edges.
      #
      #  (0)     (2)     (4)
      #   |\   /  |  \   /|
      #   | \ /   |   \ / |
      #   |  X    |    X  |
      #   | / \   |   / \ |
      #   |/   \  |  /   \|
      #  (1)----(3)-----(5)
      #
      # Triangle 0-1-3, triangle 2-3-5, triangle 3-4-5
      edges = [
        # Triangle 0-1-3
        {0, 1, 1},
        {0, 3, 1},
        {1, 3, 1},
        # Connection 2-3
        {2, 3, 1},
        # Triangle 3-4-5
        {3, 4, 1},
        {3, 5, 1},
        {4, 5, 1}
      ]

      result = MaxWeightMatching.maximum_weight_matching(edges)

      assert valid_matching?(result)
      # 7 vertices, maximum matching has 3 edges
      assert length(result) == 3
    end

    test "blossom with weighted preference" do
      # Triangle where expansion affects weight optimization.
      #
      #        (1)
      #       /   \
      #    20/     \5
      #     /       \
      #   (0)---5---(2)
      #    |         |
      #   1|         |1
      #    |         |
      #   (3)       (4)
      #
      # The 0-1 edge is heaviest inside the triangle.
      edges = [
        {0, 1, 20},
        {1, 2, 5},
        {0, 2, 5},
        {0, 3, 1},
        {2, 4, 1}
      ]

      result = MaxWeightMatching.maximum_weight_matching(edges)

      assert valid_matching?(result)
      # Optimal: match 0-1 (weight 20) and 2-4 (weight 1) = 21
      # vs 0-3 + 1-2 = 1 + 5 = 6
      assert total_weight(edges, result) == 21
    end

    test "9-cycle - large odd cycle" do
      # Odd cycle of length 9 vertices.
      # Maximum matching: 4 edges (one vertex unmatched).
      edges =
        for i <- 0..8 do
          {i, rem(i + 1, 9), 1}
        end

      result = MaxWeightMatching.maximum_weight_matching(edges)

      assert valid_matching?(result)
      assert length(result) == 4
      assert total_weight(edges, result) == 4
    end

    test "complete graph K5" do
      # Complete graph on 5 vertices.
      # All edges weight 1.
      # Maximum matching: 2 edges (5 is odd, one vertex unmatched).
      edges =
        for i <- 0..3, j <- (i + 1)..4 do
          {i, j, 1}
        end

      result = MaxWeightMatching.maximum_weight_matching(edges)

      assert valid_matching?(result)
      assert length(result) == 2
    end

    test "complete graph K6" do
      # Complete graph on 6 vertices.
      # All edges weight 1.
      # Maximum matching: 3 edges (perfect matching).
      edges =
        for i <- 0..4, j <- (i + 1)..5 do
          {i, j, 1}
        end

      result = MaxWeightMatching.maximum_weight_matching(edges)

      assert valid_matching?(result)
      assert length(result) == 3
    end

    test "deeply nested blossoms" do
      # A structure that creates nested blossoms.
      # Three triangles in a chain.
      #
      #  (0)---(1)---(3)---(4)---(6)---(7)
      #    \   /       \   /       \   /
      #     (2)         (5)         (8)
      #
      edges = [
        # Triangle 0-1-2
        {0, 1, 1},
        {1, 2, 1},
        {0, 2, 1},
        # Edge 1-3
        {1, 3, 1},
        # Triangle 3-4-5
        {3, 4, 1},
        {4, 5, 1},
        {3, 5, 1},
        # Edge 4-6
        {4, 6, 1},
        # Triangle 6-7-8
        {6, 7, 1},
        {7, 8, 1},
        {6, 8, 1}
      ]

      result = MaxWeightMatching.maximum_weight_matching(edges)

      assert valid_matching?(result)
      # 9 vertices, maximum 4 edges
      assert length(result) == 4
    end
  end
end
