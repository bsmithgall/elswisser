defmodule MaxWeightMatching.LabelTest do
  use ExUnit.Case, async: true

  alias MaxWeightMatching.{Context, Graph, Label}

  describe "assign_label_s/2 with unmatched vertex" do
    test "labels blossom as S" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      ctx = Label.assign_label_s(ctx, 0)
      blossom = Context.get_vertex_blossom(ctx, 0)

      assert blossom.label == :s
    end

    test "sets tree_edge to nil (root of tree)" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      ctx = Label.assign_label_s(ctx, 0)
      blossom = Context.get_vertex_blossom(ctx, 0)

      assert blossom.tree_edge == nil
    end

    test "adds vertex to scan queue" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      ctx = Label.assign_label_s(ctx, 0)

      refute Context.queue_empty?(ctx)
      {v, _ctx} = Context.dequeue(ctx)
      assert v == 0
    end

    test "works for multiple unmatched vertices" do
      graph = Graph.new([{0, 1, 10}, {2, 3, 5}])
      ctx = Context.new(graph)

      # Label both vertex 0 and vertex 2 as S (both unmatched)
      ctx = Label.assign_label_s(ctx, 0)
      ctx = Label.assign_label_s(ctx, 2)

      assert Context.get_vertex_blossom(ctx, 0).label == :s
      assert Context.get_vertex_blossom(ctx, 2).label == :s

      # Both should be in queue
      {v1, ctx} = Context.dequeue(ctx)
      {v2, _ctx} = Context.dequeue(ctx)
      assert Enum.sort([v1, v2]) == [0, 2]
    end
  end

  describe "assign_label_s/2 with matched vertex" do
    setup do
      # Create a graph with 3 vertices: 0 -- 1 -- 2
      # We'll set up: vertex 0 is S (root), vertex 1 is T, vertex 2 is S (via mate)
      graph = Graph.new([{0, 1, 10}, {1, 2, 10}])
      ctx = Context.new(graph)

      # Manually set up matching: 1 <-> 2 are matched
      ctx = %{ctx | vertex_mate: %{0 => -1, 1 => 2, 2 => 1}}

      # First, label vertex 0 as S (unmatched root)
      ctx = Label.assign_label_s(ctx, 0)

      # Clear queue so we can track what assign_label_t adds
      ctx = Context.clear_queue(ctx)

      # Now manually label vertex 1 as T (to set up the precondition for testing
      # assign_label_s on a matched vertex)
      id1 = Context.get_vertex_blossom_id(ctx, 1)
      ctx = Context.update_blossom(ctx, id1, label: :t, tree_edge: {0, 1})

      {:ok, ctx: ctx}
    end

    test "labels blossom as S", %{ctx: ctx} do
      ctx = Label.assign_label_s(ctx, 2)
      blossom = Context.get_vertex_blossom(ctx, 2)

      assert blossom.label == :s
    end

    test "sets tree_edge pointing to T-mate", %{ctx: ctx} do
      ctx = Label.assign_label_s(ctx, 2)
      blossom = Context.get_vertex_blossom(ctx, 2)

      # tree_edge is {y, x} where y is the T-vertex mate
      assert blossom.tree_edge == {1, 2}
    end

    test "adds vertex to scan queue", %{ctx: ctx} do
      ctx = Label.assign_label_s(ctx, 2)

      {v, _ctx} = Context.dequeue(ctx)
      assert v == 2
    end
  end

  describe "assign_label_s/2 error cases" do
    test "raises if blossom is already labeled" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      # Label once
      ctx = Label.assign_label_s(ctx, 0)

      # Attempt to label again should fail
      assert_raise ArgumentError, ~r/blossom must be unlabeled/, fn ->
        Label.assign_label_s(ctx, 0)
      end
    end

    test "raises if matched vertex's mate is not T-labeled" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      # Set up matching without proper T-labeling
      ctx = %{ctx | vertex_mate: %{0 => 1, 1 => 0}}

      # Should fail because mate's blossom is not T-labeled
      assert_raise ArgumentError, ~r/mate's blossom must be T-labeled/, fn ->
        Label.assign_label_s(ctx, 0)
      end
    end

    test "raises if unmatched vertex is not base of blossom" do
      # This is a tricky edge case - in practice, unmatched vertices
      # should always be the base of their blossom. We test the assertion.
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      # Artificially create a situation where the vertex is unmatched
      # but not the base (by modifying the blossom's base_vertex)
      id0 = Context.get_vertex_blossom_id(ctx, 0)
      ctx = Context.update_blossom(ctx, id0, base_vertex: 99)

      assert_raise ArgumentError, ~r/must be base vertex/, fn ->
        Label.assign_label_s(ctx, 0)
      end
    end
  end

  describe "assign_label_t/3" do
    setup do
      # Create a path graph: 0 -- 1 -- 2
      # Vertex 1 and 2 are matched
      graph = Graph.new([{0, 1, 10}, {1, 2, 10}])
      ctx = Context.new(graph)

      # Set up matching: 1 <-> 2
      ctx = %{ctx | vertex_mate: %{0 => -1, 1 => 2, 2 => 1}}

      # Label vertex 0 as S (root)
      ctx = Label.assign_label_s(ctx, 0)

      # Clear queue to track what assign_label_t adds
      ctx = Context.clear_queue(ctx)

      {:ok, ctx: ctx, graph: graph}
    end

    test "labels target blossom as T", %{ctx: ctx} do
      ctx = Label.assign_label_t(ctx, 0, 1)
      blossom = Context.get_vertex_blossom(ctx, 1)

      assert blossom.label == :t
    end

    test "sets tree_edge on T-blossom", %{ctx: ctx} do
      ctx = Label.assign_label_t(ctx, 0, 1)
      blossom = Context.get_vertex_blossom(ctx, 1)

      assert blossom.tree_edge == {0, 1}
    end

    test "recursively labels mate as S", %{ctx: ctx} do
      ctx = Label.assign_label_t(ctx, 0, 1)
      mate_blossom = Context.get_vertex_blossom(ctx, 2)

      assert mate_blossom.label == :s
    end

    test "sets tree_edge on mate's S-blossom", %{ctx: ctx} do
      ctx = Label.assign_label_t(ctx, 0, 1)
      mate_blossom = Context.get_vertex_blossom(ctx, 2)

      # Mate's tree_edge points back to T-vertex
      assert mate_blossom.tree_edge == {1, 2}
    end

    test "adds mate's vertices to queue", %{ctx: ctx} do
      ctx = Label.assign_label_t(ctx, 0, 1)

      # The queue should contain vertex 2 (the mate that got S-labeled)
      {v, _ctx} = Context.dequeue(ctx)
      assert v == 2
    end
  end

  describe "assign_label_t/3 error cases" do
    test "raises if x is not an S-vertex" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)
      ctx = %{ctx | vertex_mate: %{0 => -1, 1 => -1}}

      # Neither vertex is labeled, so x=0 is not an S-vertex
      assert_raise ArgumentError, ~r/must be in S-blossom/, fn ->
        Label.assign_label_t(ctx, 0, 1)
      end
    end

    test "raises if y's blossom is already labeled" do
      graph = Graph.new([{0, 1, 10}, {1, 2, 10}])
      ctx = Context.new(graph)
      ctx = %{ctx | vertex_mate: %{0 => -1, 1 => 2, 2 => 1}}

      ctx = Label.assign_label_s(ctx, 0)

      # Label vertex 1 manually
      id1 = Context.get_vertex_blossom_id(ctx, 1)
      ctx = Context.update_blossom(ctx, id1, label: :s)

      assert_raise ArgumentError, ~r/blossom must be unlabeled/, fn ->
        Label.assign_label_t(ctx, 0, 1)
      end
    end

    test "raises if T-blossom base is unmatched" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)
      # Both vertices unmatched
      ctx = %{ctx | vertex_mate: %{0 => -1, 1 => -1}}

      ctx = Label.assign_label_s(ctx, 0)

      # Trying to T-label vertex 1 which is unmatched should fail
      assert_raise ArgumentError, ~r/must be matched/, fn ->
        Label.assign_label_t(ctx, 0, 1)
      end
    end
  end

  describe "full alternating tree construction" do
    test "builds tree from root through multiple levels" do
      # Graph: 0 -- 1 -- 2 -- 3 -- 4
      # Matching: 1<->2, 3<->4
      # Expected tree: 0(S) -> 1(T) -> 2(S) -> 3(T) -> 4(S)
      graph = Graph.new([{0, 1, 10}, {1, 2, 10}, {2, 3, 10}, {3, 4, 10}])
      ctx = Context.new(graph)

      ctx = %{ctx | vertex_mate: %{0 => -1, 1 => 2, 2 => 1, 3 => 4, 4 => 3}}

      # Start the tree from unmatched vertex 0
      ctx = Label.assign_label_s(ctx, 0)
      ctx = Context.clear_queue(ctx)

      # Extend tree: T-label 1, which auto S-labels 2
      ctx = Label.assign_label_t(ctx, 0, 1)

      # Check labels
      assert Context.get_vertex_blossom(ctx, 0).label == :s
      assert Context.get_vertex_blossom(ctx, 1).label == :t
      assert Context.get_vertex_blossom(ctx, 2).label == :s
      assert Context.get_vertex_blossom(ctx, 3).label == :none
      assert Context.get_vertex_blossom(ctx, 4).label == :none

      # Continue tree extension
      ctx = Context.clear_queue(ctx)
      ctx = Label.assign_label_t(ctx, 2, 3)

      # All vertices now labeled
      assert Context.get_vertex_blossom(ctx, 3).label == :t
      assert Context.get_vertex_blossom(ctx, 4).label == :s

      # Check tree edges form a path back to root
      assert Context.get_vertex_blossom(ctx, 0).tree_edge == nil
      assert Context.get_vertex_blossom(ctx, 1).tree_edge == {0, 1}
      assert Context.get_vertex_blossom(ctx, 2).tree_edge == {1, 2}
      assert Context.get_vertex_blossom(ctx, 3).tree_edge == {2, 3}
      assert Context.get_vertex_blossom(ctx, 4).tree_edge == {3, 4}
    end
  end
end
