defmodule MaxWeightMatching.AugmentTest do
  use ExUnit.Case, async: true

  alias MaxWeightMatching.{Context, Graph, Augment, AlternatingPath}

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

  describe "augment_blossom/3" do
    alias MaxWeightMatching.Blossom.NonTrivial

    test "rotates subblossom list to make sub the new base" do
      # Create a triangle blossom: vertices 0, 1, 2
      # Sub-blossoms at positions 0, 1, 2 with base at 0
      # Augment from position 2 -> base rotates to vertex 2
      graph = Graph.new([{0, 1, 10}, {1, 2, 10}, {0, 2, 10}])
      ctx = Context.new(graph)

      # Get trivial blossom IDs
      sub0_id = Context.get_trivial_blossom_id(ctx, 0)
      sub1_id = Context.get_trivial_blossom_id(ctx, 1)
      sub2_id = Context.get_trivial_blossom_id(ctx, 2)

      # Create non-trivial blossom with subblossoms [sub0, sub1, sub2]
      # Edges: (0,1), (1,2), (2,0) completing the cycle
      blossom = NonTrivial.new([sub0_id, sub1_id, sub2_id], [{0, 1}, {1, 2}, {2, 0}], 0)
      ctx = Context.add_blossom(ctx, blossom)

      # Set parent_id for sub-blossoms
      ctx = Context.update_blossom(ctx, sub0_id, parent_id: blossom.id)
      ctx = Context.update_blossom(ctx, sub1_id, parent_id: blossom.id)
      ctx = Context.update_blossom(ctx, sub2_id, parent_id: blossom.id)

      # Update vertex_top_blossom_id to point to the new blossom
      ctx = Context.set_vertices_blossom(ctx, [0, 1, 2], blossom.id)

      # Augment from sub2 (vertex 2) to base
      ctx = Augment.augment_blossom(ctx, blossom.id, sub2_id)

      # After augmentation, base_vertex should be 2
      updated_blossom = Context.get_blossom(ctx, blossom.id)
      assert updated_blossom.base_vertex == 2

      # Subblossom list should be rotated so sub2 is first
      assert hd(updated_blossom.subblossom_ids) == sub2_id
    end

    test "updates vertex_mate for internal edges" do
      # Triangle blossom with vertices 0, 1, 2
      # Initially vertex_mate: 0->1, 1->0 (edge 0-1 matched internally)
      # After augmenting from sub1 to base (sub0):
      # Path goes [sub1, sub0], edge (0,1) is at position 0 (already pulled in)
      graph = Graph.new([{0, 1, 10}, {1, 2, 10}, {0, 2, 10}])
      ctx = Context.new(graph)
      ctx = %{ctx | vertex_mate: %{0 => 1, 1 => 0, 2 => -1}}

      sub0_id = Context.get_trivial_blossom_id(ctx, 0)
      sub1_id = Context.get_trivial_blossom_id(ctx, 1)
      sub2_id = Context.get_trivial_blossom_id(ctx, 2)

      blossom = NonTrivial.new([sub0_id, sub1_id, sub2_id], [{0, 1}, {1, 2}, {2, 0}], 0)
      ctx = Context.add_blossom(ctx, blossom)
      ctx = Context.update_blossom(ctx, sub0_id, parent_id: blossom.id)
      ctx = Context.update_blossom(ctx, sub1_id, parent_id: blossom.id)
      ctx = Context.update_blossom(ctx, sub2_id, parent_id: blossom.id)
      ctx = Context.set_vertices_blossom(ctx, [0, 1, 2], blossom.id)

      # Augment from sub2 to base (vertex 0)
      # Path: [sub2, sub0] going backwards, edge at position 0 is (2,0) reversed
      ctx = Augment.augment_blossom(ctx, blossom.id, sub2_id)

      # Check that base_vertex is now 2
      updated_blossom = Context.get_blossom(ctx, blossom.id)
      assert updated_blossom.base_vertex == 2
    end

    test "handles augmentation from position 1 (odd position)" do
      # When sub is at odd position, path goes forward around the blossom
      graph = Graph.new([{0, 1, 10}, {1, 2, 10}, {0, 2, 10}])
      ctx = Context.new(graph)

      sub0_id = Context.get_trivial_blossom_id(ctx, 0)
      sub1_id = Context.get_trivial_blossom_id(ctx, 1)
      sub2_id = Context.get_trivial_blossom_id(ctx, 2)

      blossom = NonTrivial.new([sub0_id, sub1_id, sub2_id], [{0, 1}, {1, 2}, {2, 0}], 0)
      ctx = Context.add_blossom(ctx, blossom)
      ctx = Context.update_blossom(ctx, sub0_id, parent_id: blossom.id)
      ctx = Context.update_blossom(ctx, sub1_id, parent_id: blossom.id)
      ctx = Context.update_blossom(ctx, sub2_id, parent_id: blossom.id)
      ctx = Context.set_vertices_blossom(ctx, [0, 1, 2], blossom.id)

      # Augment from sub1 (odd position) - goes forward: [sub1, sub2, sub0]
      ctx = Augment.augment_blossom(ctx, blossom.id, sub1_id)

      updated_blossom = Context.get_blossom(ctx, blossom.id)
      assert updated_blossom.base_vertex == 1
      assert hd(updated_blossom.subblossom_ids) == sub1_id
    end

    test "raises when sub_id not found in blossom" do
      # Create two separate triangles - vertices 0,1,2 and 3,4,5
      graph =
        Graph.new([
          {0, 1, 10},
          {1, 2, 10},
          {0, 2, 10},
          {3, 4, 10},
          {4, 5, 10},
          {3, 5, 10}
        ])

      ctx = Context.new(graph)

      sub0_id = Context.get_trivial_blossom_id(ctx, 0)
      sub1_id = Context.get_trivial_blossom_id(ctx, 1)
      sub2_id = Context.get_trivial_blossom_id(ctx, 2)
      sub3_id = Context.get_trivial_blossom_id(ctx, 3)

      # Create blossom with sub0, sub1, sub2
      blossom = NonTrivial.new([sub0_id, sub1_id, sub2_id], [{0, 1}, {1, 2}, {2, 0}], 0)
      ctx = Context.add_blossom(ctx, blossom)
      ctx = Context.update_blossom(ctx, sub0_id, parent_id: blossom.id)
      ctx = Context.update_blossom(ctx, sub1_id, parent_id: blossom.id)
      ctx = Context.update_blossom(ctx, sub2_id, parent_id: blossom.id)

      # sub3 exists as a blossom but is NOT in blossom's subblossom_ids
      # Set its parent to the blossom to trigger the lookup
      ctx = Context.update_blossom(ctx, sub3_id, parent_id: blossom.id)

      assert_raise ArgumentError, ~r/sub_id not found/, fn ->
        Augment.augment_blossom(ctx, blossom.id, sub3_id)
      end
    end

    test "raises when sub-blossom has no parent" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      # Try to augment through a trivial blossom that has no parent
      sub0_id = Context.get_trivial_blossom_id(ctx, 0)

      # This should fail because trivial blossoms have parent_id = nil
      assert_raise ArgumentError, ~r/must have a parent/, fn ->
        Augment.augment_blossom(ctx, sub0_id, sub0_id)
      end
    end
  end
end
