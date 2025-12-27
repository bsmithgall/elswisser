defmodule Blossom.MaxWeightMatching.AugmentTest do
  use ExUnit.Case, async: true

  alias Blossom.MaxWeightMatching.{Context, Graph, Augment, AlternatingPath}

  describe "augment_matching/2" do
    test "matches two unmatched vertices via single edge" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      # Both vertices unmatched
      assert ctx.vertex_mate[0] == -1
      assert ctx.vertex_mate[1] == -1

      # Path is just the single edge
      path = %AlternatingPath{edges: [{0, 1}]}

      ctx = Augment.augment_matching(ctx, path)

      # Both vertices now matched to each other
      assert ctx.vertex_mate[0] == 1
      assert ctx.vertex_mate[1] == 0
    end

    test "augments 3-edge path correctly" do
      # Path: 0 -- 1 -- 2 -- 3
      # Initially: 1<->2 matched
      # After augmenting path [0,1], [1,2], [2,3]:
      #   - Edge [0,1] becomes matched
      #   - Edge [1,2] becomes unmatched (was matched)
      #   - Edge [2,3] becomes matched
      graph = Graph.new([{0, 1, 10}, {1, 2, 10}, {2, 3, 10}])
      ctx = Context.new(graph)
      ctx = %{ctx | vertex_mate: %{0 => -1, 1 => 2, 2 => 1, 3 => -1}}

      path = %AlternatingPath{edges: [{0, 1}, {1, 2}, {2, 3}]}

      ctx = Augment.augment_matching(ctx, path)

      # Edges at indices 0, 2 become matched
      assert ctx.vertex_mate[0] == 1
      assert ctx.vertex_mate[1] == 0
      assert ctx.vertex_mate[2] == 3
      assert ctx.vertex_mate[3] == 2
    end

    test "augments 5-edge path correctly" do
      # Longer augmenting path
      # Path: 0 -- 1 -- 2 -- 3 -- 4 -- 5
      # Initially: 1<->2, 3<->4 matched
      # After augmenting:
      #   - [0,1] matched
      #   - [2,3] matched
      #   - [4,5] matched
      graph =
        Graph.new([
          {0, 1, 10},
          {1, 2, 10},
          {2, 3, 10},
          {3, 4, 10},
          {4, 5, 10}
        ])

      ctx = Context.new(graph)
      ctx = %{ctx | vertex_mate: %{0 => -1, 1 => 2, 2 => 1, 3 => 4, 4 => 3, 5 => -1}}

      path = %AlternatingPath{
        edges: [{0, 1}, {1, 2}, {2, 3}, {3, 4}, {4, 5}]
      }

      ctx = Augment.augment_matching(ctx, path)

      # New matching: 0<->1, 2<->3, 4<->5
      assert ctx.vertex_mate[0] == 1
      assert ctx.vertex_mate[1] == 0
      assert ctx.vertex_mate[2] == 3
      assert ctx.vertex_mate[3] == 2
      assert ctx.vertex_mate[4] == 5
      assert ctx.vertex_mate[5] == 4
    end

    test "increases matching size by one" do
      # Before: 1 matched pair (1<->2)
      # After: 2 matched pairs (0<->1, 2<->3)
      graph = Graph.new([{0, 1, 10}, {1, 2, 10}, {2, 3, 10}])
      ctx = Context.new(graph)
      ctx = %{ctx | vertex_mate: %{0 => -1, 1 => 2, 2 => 1, 3 => -1}}

      initial_matched =
        ctx.vertex_mate
        |> Map.values()
        |> Enum.count(&(&1 != -1))
        |> div(2)

      path = %AlternatingPath{edges: [{0, 1}, {1, 2}, {2, 3}]}
      ctx = Augment.augment_matching(ctx, path)

      final_matched =
        ctx.vertex_mate
        |> Map.values()
        |> Enum.count(&(&1 != -1))
        |> div(2)

      assert final_matched == initial_matched + 1
    end

    test "preserves matching for vertices not on path" do
      # Graph has 6 vertices, but path only involves 0-3
      # Vertices 4<->5 should remain matched
      graph =
        Graph.new([
          {0, 1, 10},
          {1, 2, 10},
          {2, 3, 10},
          {4, 5, 10}
        ])

      ctx = Context.new(graph)

      ctx = %{
        ctx
        | vertex_mate: %{0 => -1, 1 => 2, 2 => 1, 3 => -1, 4 => 5, 5 => 4}
      }

      path = %AlternatingPath{edges: [{0, 1}, {1, 2}, {2, 3}]}
      ctx = Augment.augment_matching(ctx, path)

      # Vertices 4 and 5 unchanged
      assert ctx.vertex_mate[4] == 5
      assert ctx.vertex_mate[5] == 4
    end
  end

  describe "augment_matching/2 - edge cases" do
    test "handles single-edge path" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      path = %AlternatingPath{edges: [{0, 1}]}
      ctx = Augment.augment_matching(ctx, path)

      assert ctx.vertex_mate[0] == 1
      assert ctx.vertex_mate[1] == 0
    end

    test "handles path with swapped edge direction" do
      # Sometimes trace_alternating_paths produces edges in either direction
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      # Edge tuple is (1, 0) instead of (0, 1)
      path = %AlternatingPath{edges: [{1, 0}]}
      ctx = Augment.augment_matching(ctx, path)

      # Should still work - matching is symmetric
      assert ctx.vertex_mate[1] == 0
      assert ctx.vertex_mate[0] == 1
    end
  end
end
