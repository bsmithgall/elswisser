defmodule MaxWeightMatching.ContextTest do
  use ExUnit.Case, async: true

  alias MaxWeightMatching.{Context, Graph}
  alias MaxWeightMatching.Blossom.Trivial

  describe "new/1 with empty graph" do
    test "creates empty context" do
      graph = Graph.new([])
      ctx = Context.new(graph)

      assert ctx.graph == graph
      assert ctx.vertex_mate == %{}
      assert ctx.blossoms == %{}
      assert ctx.vertex_top_blossom_id == %{}
      assert ctx.vertex_dual_2x == %{}
      assert ctx.vertex_best_edge == %{}
      assert :queue.is_empty(ctx.queue)
    end
  end

  describe "new/1 with single edge" do
    test "creates context with 2 trivial blossoms" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      assert map_size(ctx.blossoms) == 2
    end

    test "maps vertices to their trivial blossoms" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      id0 = ctx.vertex_top_blossom_id[0]
      id1 = ctx.vertex_top_blossom_id[1]

      assert is_reference(id0)
      assert is_reference(id1)
      assert id0 != id1
    end

    test "initializes vertex_mate to -1 for all vertices" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      assert ctx.vertex_mate[0] == -1
      assert ctx.vertex_mate[1] == -1
    end

    test "initializes vertex_dual_2x to max weight" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      assert ctx.vertex_dual_2x[0] == 10
      assert ctx.vertex_dual_2x[1] == 10
    end

    test "initializes vertex_best_edge to -1" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      assert ctx.vertex_best_edge[0] == -1
      assert ctx.vertex_best_edge[1] == -1
    end

    test "initializes queue as empty" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      assert :queue.is_empty(ctx.queue)
    end
  end

  describe "new/1 with multiple edges" do
    test "uses maximum weight for vertex_dual_2x" do
      graph = Graph.new([{0, 1, 5}, {1, 2, 15}, {0, 2, 10}])
      ctx = Context.new(graph)

      # Max weight is 15
      assert ctx.vertex_dual_2x[0] == 15
      assert ctx.vertex_dual_2x[1] == 15
      assert ctx.vertex_dual_2x[2] == 15
    end

    test "creates trivial blossom for each vertex" do
      graph = Graph.new([{0, 1, 5}, {1, 2, 10}, {2, 3, 15}])
      ctx = Context.new(graph)

      assert map_size(ctx.blossoms) == 4

      # Each blossom should be trivial
      for {_id, blossom} <- ctx.blossoms do
        assert %Trivial{} = blossom
      end
    end

    test "trivial blossoms have correct base_vertex" do
      graph = Graph.new([{0, 1, 5}, {1, 2, 10}])
      ctx = Context.new(graph)

      # Get blossoms through vertex mapping
      b0 = Context.get_vertex_blossom(ctx, 0)
      b1 = Context.get_vertex_blossom(ctx, 1)
      b2 = Context.get_vertex_blossom(ctx, 2)

      assert b0.base_vertex == 0
      assert b1.base_vertex == 1
      assert b2.base_vertex == 2
    end
  end

  describe "get_blossom/2" do
    test "returns blossom by ID" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      id0 = ctx.vertex_top_blossom_id[0]
      blossom = Context.get_blossom(ctx, id0)

      assert %Trivial{} = blossom
      assert blossom.base_vertex == 0
    end

    test "raises for unknown ID" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      assert_raise KeyError, fn ->
        Context.get_blossom(ctx, make_ref())
      end
    end
  end

  describe "get_vertex_blossom/2" do
    test "returns top-level blossom for vertex" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      blossom = Context.get_vertex_blossom(ctx, 0)

      assert %Trivial{} = blossom
      assert blossom.base_vertex == 0
    end
  end

  describe "get_vertex_blossom_id/2" do
    test "returns blossom ID for vertex" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      id = Context.get_vertex_blossom_id(ctx, 0)

      assert is_reference(id)
      assert Map.has_key?(ctx.blossoms, id)
    end
  end

  describe "update_blossom/3" do
    test "updates blossom label" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      id0 = ctx.vertex_top_blossom_id[0]
      ctx = Context.update_blossom(ctx, id0, label: :s)

      updated = Context.get_blossom(ctx, id0)
      assert updated.label == :s
    end

    test "updates multiple fields" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      id0 = ctx.vertex_top_blossom_id[0]
      ctx = Context.update_blossom(ctx, id0, label: :t, tree_edge: {1, 0}, marker: true)

      updated = Context.get_blossom(ctx, id0)
      assert updated.label == :t
      assert updated.tree_edge == {1, 0}
      assert updated.marker == true
    end

    test "returns new context (immutable)" do
      graph = Graph.new([{0, 1, 10}])
      original_ctx = Context.new(graph)

      id0 = original_ctx.vertex_top_blossom_id[0]
      new_ctx = Context.update_blossom(original_ctx, id0, label: :s)

      # Original should be unchanged
      assert Context.get_blossom(original_ctx, id0).label == :none
      # New should be updated
      assert Context.get_blossom(new_ctx, id0).label == :s
    end
  end

  describe "same_blossom?/3" do
    test "returns true for vertices in same trivial blossom" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      # Same vertex maps to same blossom
      assert Context.same_blossom?(ctx, 0, 0)
    end

    test "returns false for vertices in different blossoms" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      refute Context.same_blossom?(ctx, 0, 1)
    end
  end

  describe "add_blossom/2" do
    test "adds new blossom to context" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      new_blossom = Trivial.new(99)
      ctx = Context.add_blossom(ctx, new_blossom)

      assert Map.has_key?(ctx.blossoms, new_blossom.id)
      assert Context.get_blossom(ctx, new_blossom.id) == new_blossom
    end
  end

  describe "remove_blossom/2" do
    test "removes blossom from context" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      id0 = ctx.vertex_top_blossom_id[0]
      ctx = Context.remove_blossom(ctx, id0)

      refute Map.has_key?(ctx.blossoms, id0)
    end
  end

  describe "set_vertex_blossom/3" do
    test "updates vertex to blossom mapping" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      new_id = make_ref()
      ctx = Context.set_vertex_blossom(ctx, 0, new_id)

      assert Context.get_vertex_blossom_id(ctx, 0) == new_id
    end
  end

  describe "set_vertices_blossom/3" do
    test "updates multiple vertices to same blossom" do
      graph = Graph.new([{0, 1, 10}, {1, 2, 5}])
      ctx = Context.new(graph)

      new_id = make_ref()
      ctx = Context.set_vertices_blossom(ctx, [0, 1, 2], new_id)

      assert Context.get_vertex_blossom_id(ctx, 0) == new_id
      assert Context.get_vertex_blossom_id(ctx, 1) == new_id
      assert Context.get_vertex_blossom_id(ctx, 2) == new_id
    end
  end

  describe "blossom_vertices/2" do
    test "returns vertices from trivial blossom" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      id0 = ctx.vertex_top_blossom_id[0]
      vertices = Context.blossom_vertices(ctx, id0)

      assert vertices == [0]
    end
  end

  describe "queue operations" do
    test "enqueue adds vertices to queue" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      ctx = Context.enqueue(ctx, [0, 1])

      refute Context.queue_empty?(ctx)
    end

    test "dequeue returns vertices in FIFO order" do
      graph = Graph.new([{0, 1, 10}, {1, 2, 5}])
      ctx = Context.new(graph)

      ctx = Context.enqueue(ctx, [0, 1, 2])

      {v1, ctx} = Context.dequeue(ctx)
      {v2, ctx} = Context.dequeue(ctx)
      {v3, ctx} = Context.dequeue(ctx)

      assert v1 == 0
      assert v2 == 1
      assert v3 == 2
      assert Context.queue_empty?(ctx)
    end

    test "dequeue returns :empty when queue is empty" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      assert Context.dequeue(ctx) == :empty
    end

    test "queue_empty? returns true for empty queue" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      assert Context.queue_empty?(ctx)
    end

    test "queue_empty? returns false after enqueue" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      ctx = Context.enqueue(ctx, [0])

      refute Context.queue_empty?(ctx)
    end

    test "clear_queue empties the queue" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      ctx = Context.enqueue(ctx, [0, 1])
      refute Context.queue_empty?(ctx)

      ctx = Context.clear_queue(ctx)
      assert Context.queue_empty?(ctx)
    end
  end
end
