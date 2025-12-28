defmodule Blossom.MaxWeightMatching.BlossomOpsTest do
  @moduledoc """
  Tests for blossom creation and navigation operations.
  """

  use ExUnit.Case, async: true

  alias Blossom.MaxWeightMatching.BlossomOps
  alias Blossom.MaxWeightMatching.Blossom.NonTrivial
  alias Blossom.MaxWeightMatching.AlternatingPath
  alias Blossom.MaxWeightMatching.Context
  alias Blossom.MaxWeightMatching.Graph

  describe "find_path_through_blossom/2" do
    setup do
      # Create a 5-blossom: [A, B, C, D, E] with edges connecting them
      # The base vertex is in A (position 0)
      sub_ids = for _ <- 1..5, do: make_ref()
      edges = [{0, 1}, {1, 2}, {2, 3}, {3, 4}, {4, 0}]

      blossom = %NonTrivial{
        id: make_ref(),
        base_vertex: 0,
        subblossom_ids: sub_ids,
        edges: edges
      }

      {:ok, blossom: blossom, sub_ids: sub_ids, edges: edges}
    end

    test "from position 0 (base) returns just the base", %{blossom: blossom, sub_ids: sub_ids} do
      # Position 0 is even, so walk backwards from 0 to 0
      {nodes, edges} = BlossomOps.find_path_through_blossom(blossom, Enum.at(sub_ids, 0))

      assert nodes == [Enum.at(sub_ids, 0)]
      assert edges == []
    end

    test "from position 2 (even) walks backwards", %{blossom: blossom, sub_ids: sub_ids} do
      # Position 2 is even, walk backwards: [C, B, A]
      # Edges: flip edges[1], edges[0] -> [{2,1}, {1,0}]
      {nodes, edges} = BlossomOps.find_path_through_blossom(blossom, Enum.at(sub_ids, 2))

      assert nodes == [Enum.at(sub_ids, 2), Enum.at(sub_ids, 1), Enum.at(sub_ids, 0)]
      assert edges == [{2, 1}, {1, 0}]
    end

    test "from position 4 (even) walks backwards", %{blossom: blossom, sub_ids: sub_ids} do
      # Position 4 is even, walk backwards: [E, D, C, B, A]
      # Edges: flip edges[3..0] -> [{4,3}, {3,2}, {2,1}, {1,0}]
      {nodes, edges} = BlossomOps.find_path_through_blossom(blossom, Enum.at(sub_ids, 4))

      expected_nodes = Enum.map(4..0//-1, fn i -> Enum.at(sub_ids, i) end)
      assert nodes == expected_nodes
      assert edges == [{4, 3}, {3, 2}, {2, 1}, {1, 0}]
    end

    test "from position 1 (odd) walks forward", %{blossom: blossom, sub_ids: sub_ids} do
      # Position 1 is odd, walk forward: [B, C, D, E, A]
      # Edges: edges[1..4] -> [{1,2}, {2,3}, {3,4}, {4,0}]
      {nodes, edges} = BlossomOps.find_path_through_blossom(blossom, Enum.at(sub_ids, 1))

      expected_nodes =
        [1, 2, 3, 4, 0]
        |> Enum.map(fn i -> Enum.at(sub_ids, i) end)

      assert nodes == expected_nodes
      assert edges == [{1, 2}, {2, 3}, {3, 4}, {4, 0}]
    end

    test "from position 3 (odd) walks forward", %{blossom: blossom, sub_ids: sub_ids} do
      # Position 3 is odd, walk forward: [D, E, A]
      # Edges: edges[3..4] -> [{3,4}, {4,0}]
      {nodes, edges} = BlossomOps.find_path_through_blossom(blossom, Enum.at(sub_ids, 3))

      expected_nodes =
        [3, 4, 0]
        |> Enum.map(fn i -> Enum.at(sub_ids, i) end)

      assert nodes == expected_nodes
      assert edges == [{3, 4}, {4, 0}]
    end

    test "raises when sub_id not found", %{blossom: blossom} do
      assert_raise ArgumentError, ~r/sub_id not found/, fn ->
        BlossomOps.find_path_through_blossom(blossom, make_ref())
      end
    end
  end

  describe "find_path_through_blossom/2 with 3-blossom" do
    setup do
      sub_ids = for _ <- 1..3, do: make_ref()
      edges = [{0, 1}, {1, 2}, {2, 0}]

      blossom = %NonTrivial{
        id: make_ref(),
        base_vertex: 0,
        subblossom_ids: sub_ids,
        edges: edges
      }

      {:ok, blossom: blossom, sub_ids: sub_ids}
    end

    test "from position 1 walks forward", %{blossom: blossom, sub_ids: sub_ids} do
      # Position 1 is odd, walk forward: [B, C, A]
      {nodes, edges} = BlossomOps.find_path_through_blossom(blossom, Enum.at(sub_ids, 1))

      expected_nodes = Enum.map([1, 2, 0], fn i -> Enum.at(sub_ids, i) end)
      assert nodes == expected_nodes
      assert edges == [{1, 2}, {2, 0}]
    end

    test "from position 2 walks backward", %{blossom: blossom, sub_ids: sub_ids} do
      # Position 2 is even, walk backwards: [C, B, A]
      {nodes, edges} = BlossomOps.find_path_through_blossom(blossom, Enum.at(sub_ids, 2))

      expected_nodes = Enum.map([2, 1, 0], fn i -> Enum.at(sub_ids, i) end)
      assert nodes == expected_nodes
      assert edges == [{2, 1}, {1, 0}]
    end
  end

  describe "make_blossom/2" do
    test "creates blossom from triangle path" do
      # Set up a triangle graph: 0-1-2-0
      graph = Graph.new([{0, 1, 10}, {1, 2, 10}, {2, 0, 10}])
      ctx = Context.new(graph)

      # Label all trivial blossoms as S
      ctx =
        Enum.reduce(0..2, ctx, fn v, ctx ->
          blossom_id = Context.get_vertex_blossom_id(ctx, v)
          Context.update_blossom(ctx, blossom_id, label: :s)
        end)

      # Create an alternating path that forms a cycle
      path = %AlternatingPath{edges: [{0, 1}, {1, 2}, {2, 0}]}

      # Make the blossom
      ctx = BlossomOps.make_blossom(ctx, path)

      # Verify a non-trivial blossom was created
      new_blossom = Context.get_vertex_blossom(ctx, 0)
      assert %NonTrivial{} = new_blossom
      assert new_blossom.label == :s
      assert new_blossom.base_vertex == 0
      assert length(new_blossom.subblossom_ids) == 3
      assert length(new_blossom.edges) == 3

      # Verify all vertices point to the new blossom
      assert Context.get_vertex_blossom_id(ctx, 0) == new_blossom.id
      assert Context.get_vertex_blossom_id(ctx, 1) == new_blossom.id
      assert Context.get_vertex_blossom_id(ctx, 2) == new_blossom.id

      # Verify parent_id is set on sub-blossoms
      for sub_id <- new_blossom.subblossom_ids do
        sub = Context.get_blossom(ctx, sub_id)
        assert sub.parent_id == new_blossom.id
      end
    end

    test "creates blossom from pentagon path" do
      # Set up a pentagon graph: 0-1-2-3-4-0
      edges =
        for {i, j} <- [{0, 1}, {1, 2}, {2, 3}, {3, 4}, {4, 0}] do
          {i, j, 10}
        end

      graph = Graph.new(edges)
      ctx = Context.new(graph)

      # Label all trivial blossoms as S
      ctx =
        Enum.reduce(0..4, ctx, fn v, ctx ->
          blossom_id = Context.get_vertex_blossom_id(ctx, v)
          Context.update_blossom(ctx, blossom_id, label: :s)
        end)

      # Create an alternating path that forms a cycle
      path = %AlternatingPath{edges: [{0, 1}, {1, 2}, {2, 3}, {3, 4}, {4, 0}]}

      # Make the blossom
      ctx = BlossomOps.make_blossom(ctx, path)

      # Verify a non-trivial blossom was created
      new_blossom = Context.get_vertex_blossom(ctx, 0)
      assert %NonTrivial{} = new_blossom
      assert length(new_blossom.subblossom_ids) == 5

      # Verify all vertices point to the new blossom
      for v <- 0..4 do
        assert Context.get_vertex_blossom_id(ctx, v) == new_blossom.id
      end
    end

    test "enqueues vertices from T-labeled sub-blossoms" do
      # Set up a triangle graph
      graph = Graph.new([{0, 1, 10}, {1, 2, 10}, {2, 0, 10}])
      ctx = Context.new(graph)

      # Label blossoms: 0 as S, 1 as T, 2 as S
      id0 = Context.get_vertex_blossom_id(ctx, 0)
      id1 = Context.get_vertex_blossom_id(ctx, 1)
      id2 = Context.get_vertex_blossom_id(ctx, 2)

      ctx = Context.update_blossom(ctx, id0, label: :s)
      ctx = Context.update_blossom(ctx, id1, label: :t)
      ctx = Context.update_blossom(ctx, id2, label: :s)

      # Create alternating path
      path = %AlternatingPath{edges: [{0, 1}, {1, 2}, {2, 0}]}

      # Make the blossom
      ctx = BlossomOps.make_blossom(ctx, path)

      # Verify vertex 1 (from T-blossom) was enqueued
      assert not Context.queue_empty?(ctx)

      {v, ctx} = Context.dequeue(ctx)
      assert v == 1

      # Queue should be empty now (only vertex 1 was from T-blossom)
      assert Context.queue_empty?(ctx)
    end

    test "inherits tree_edge from first sub-blossom" do
      # Set up a triangle graph
      graph = Graph.new([{0, 1, 10}, {1, 2, 10}, {2, 0, 10}])
      ctx = Context.new(graph)

      # Set up tree structure: vertex 0's blossom is root, has tree_edge
      id0 = Context.get_vertex_blossom_id(ctx, 0)
      id1 = Context.get_vertex_blossom_id(ctx, 1)
      id2 = Context.get_vertex_blossom_id(ctx, 2)

      ctx = Context.update_blossom(ctx, id0, label: :s, tree_edge: {5, 0})
      ctx = Context.update_blossom(ctx, id1, label: :s)
      ctx = Context.update_blossom(ctx, id2, label: :s)

      path = %AlternatingPath{edges: [{0, 1}, {1, 2}, {2, 0}]}
      ctx = BlossomOps.make_blossom(ctx, path)

      new_blossom = Context.get_vertex_blossom(ctx, 0)
      assert new_blossom.tree_edge == {5, 0}
    end

    test "raises on path with fewer than 3 edges" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      path = %AlternatingPath{edges: [{0, 1}]}

      assert_raise ArgumentError, ~r/at least 3 edges/, fn ->
        BlossomOps.make_blossom(ctx, path)
      end
    end

    test "raises on path with even number of edges" do
      graph = Graph.new([{0, 1, 10}, {1, 2, 10}, {2, 3, 10}, {3, 0, 10}])
      ctx = Context.new(graph)

      path = %AlternatingPath{edges: [{0, 1}, {1, 2}, {2, 3}, {3, 0}]}

      assert_raise ArgumentError, ~r/odd length/, fn ->
        BlossomOps.make_blossom(ctx, path)
      end
    end

    test "correctly updates vertex_top_blossom_id for all vertices" do
      # Set up a pentagon graph
      edges = for {i, j} <- [{0, 1}, {1, 2}, {2, 3}, {3, 4}, {4, 0}], do: {i, j, 10}
      graph = Graph.new(edges)
      ctx = Context.new(graph)

      # Label all as S
      ctx =
        Enum.reduce(0..4, ctx, fn v, ctx ->
          id = Context.get_vertex_blossom_id(ctx, v)
          Context.update_blossom(ctx, id, label: :s)
        end)

      path = %AlternatingPath{edges: [{0, 1}, {1, 2}, {2, 3}, {3, 4}, {4, 0}]}
      ctx = BlossomOps.make_blossom(ctx, path)

      # Get the new blossom
      new_blossom = Context.get_vertex_blossom(ctx, 0)

      # Verify all vertices point to the same new blossom
      for v <- 0..4 do
        assert Context.get_vertex_blossom_id(ctx, v) == new_blossom.id,
               "Vertex #{v} should point to new blossom"
      end
    end

    test "sets parent_id correctly on all sub-blossoms" do
      graph = Graph.new([{0, 1, 10}, {1, 2, 10}, {2, 0, 10}])
      ctx = Context.new(graph)

      id0 = Context.get_vertex_blossom_id(ctx, 0)
      id1 = Context.get_vertex_blossom_id(ctx, 1)
      id2 = Context.get_vertex_blossom_id(ctx, 2)

      ctx = Context.update_blossom(ctx, id0, label: :s)
      ctx = Context.update_blossom(ctx, id1, label: :s)
      ctx = Context.update_blossom(ctx, id2, label: :s)

      path = %AlternatingPath{edges: [{0, 1}, {1, 2}, {2, 0}]}
      ctx = BlossomOps.make_blossom(ctx, path)

      new_blossom = Context.get_vertex_blossom(ctx, 0)

      # Verify parent_id is set on all sub-blossoms
      for sub_id <- [id0, id1, id2] do
        sub = Context.get_blossom(ctx, sub_id)

        assert sub.parent_id == new_blossom.id,
               "Sub-blossom should have parent_id set to new blossom"
      end
    end

    test "raises when first sub-blossom is not labeled S" do
      graph = Graph.new([{0, 1, 10}, {1, 2, 10}, {2, 0, 10}])
      ctx = Context.new(graph)

      id0 = Context.get_vertex_blossom_id(ctx, 0)
      id1 = Context.get_vertex_blossom_id(ctx, 1)
      id2 = Context.get_vertex_blossom_id(ctx, 2)

      # First sub-blossom is NOT labeled S
      ctx = Context.update_blossom(ctx, id0, label: :t)
      ctx = Context.update_blossom(ctx, id1, label: :s)
      ctx = Context.update_blossom(ctx, id2, label: :s)

      path = %AlternatingPath{edges: [{0, 1}, {1, 2}, {2, 0}]}

      assert_raise ArgumentError, ~r/first sub-blossom must have label :s/, fn ->
        BlossomOps.make_blossom(ctx, path)
      end
    end
  end

  describe "expand_unlabeled_blossom/2" do
    test "converts sub-blossoms to top-level" do
      graph = Graph.new([{0, 1, 10}, {1, 2, 10}, {2, 0, 10}])
      ctx = Context.new(graph)

      # Create a blossom first
      ctx =
        Enum.reduce(0..2, ctx, fn v, ctx ->
          id = Context.get_vertex_blossom_id(ctx, v)
          Context.update_blossom(ctx, id, label: :s)
        end)

      path = %AlternatingPath{edges: [{0, 1}, {1, 2}, {2, 0}]}
      ctx = BlossomOps.make_blossom(ctx, path)

      blossom = Context.get_vertex_blossom(ctx, 0)
      sub_ids = blossom.subblossom_ids

      # Clear label to make it unlabeled
      ctx = Context.update_blossom(ctx, blossom.id, label: :none)

      # Clear sub-blossom labels
      ctx =
        Enum.reduce(sub_ids, ctx, fn id, ctx ->
          Context.update_blossom(ctx, id, label: :none)
        end)

      # Expand the blossom
      ctx = BlossomOps.expand_unlabeled_blossom(ctx, blossom.id)

      # Sub-blossoms should now be top-level
      for sub_id <- sub_ids do
        sub = Context.get_blossom(ctx, sub_id)
        assert sub.parent_id == nil
      end

      # Vertices should point to their trivial blossoms
      for v <- 0..2 do
        trivial_id = Context.get_trivial_blossom_id(ctx, v)
        assert Context.get_vertex_blossom_id(ctx, v) == trivial_id
      end

      # Original blossom should be removed
      assert_raise KeyError, fn ->
        Context.get_blossom(ctx, blossom.id)
      end
    end

    test "raises when blossom has parent" do
      graph = Graph.new([{0, 1, 10}, {1, 2, 10}, {2, 0, 10}])
      ctx = Context.new(graph)

      # Create a blossom
      ctx =
        Enum.reduce(0..2, ctx, fn v, ctx ->
          id = Context.get_vertex_blossom_id(ctx, v)
          Context.update_blossom(ctx, id, label: :s)
        end)

      path = %AlternatingPath{edges: [{0, 1}, {1, 2}, {2, 0}]}
      ctx = BlossomOps.make_blossom(ctx, path)

      blossom = Context.get_vertex_blossom(ctx, 0)

      # Get a sub-blossom (which has parent_id set)
      sub_id = hd(blossom.subblossom_ids)

      assert_raise ArgumentError, ~r/must be top-level/, fn ->
        BlossomOps.expand_unlabeled_blossom(ctx, sub_id)
      end
    end

    test "raises when blossom is labeled" do
      graph = Graph.new([{0, 1, 10}, {1, 2, 10}, {2, 0, 10}])
      ctx = Context.new(graph)

      ctx =
        Enum.reduce(0..2, ctx, fn v, ctx ->
          id = Context.get_vertex_blossom_id(ctx, v)
          Context.update_blossom(ctx, id, label: :s)
        end)

      path = %AlternatingPath{edges: [{0, 1}, {1, 2}, {2, 0}]}
      ctx = BlossomOps.make_blossom(ctx, path)

      blossom = Context.get_vertex_blossom(ctx, 0)

      # Blossom is labeled :s, should fail
      assert_raise ArgumentError, ~r/must be unlabeled/, fn ->
        BlossomOps.expand_unlabeled_blossom(ctx, blossom.id)
      end
    end
  end

  describe "expand_t_blossom/2" do
    test "assigns alternating S/T labels to sub-blossoms" do
      # Create a triangle graph with external connection
      graph =
        Graph.new([
          {0, 1, 10},
          {1, 2, 10},
          {2, 0, 10},
          {0, 3, 10}
        ])

      ctx = Context.new(graph)

      # Label all as S, create blossom
      ctx =
        Enum.reduce(0..3, ctx, fn v, ctx ->
          id = Context.get_vertex_blossom_id(ctx, v)
          Context.update_blossom(ctx, id, label: :s)
        end)

      path = %AlternatingPath{edges: [{0, 1}, {1, 2}, {2, 0}]}
      ctx = BlossomOps.make_blossom(ctx, path)

      blossom = Context.get_vertex_blossom(ctx, 0)
      sub_ids = blossom.subblossom_ids

      # Set blossom to T with tree_edge from vertex 3
      ctx = Context.update_blossom(ctx, blossom.id, label: :t, tree_edge: {3, 0})

      # Clear sub-blossom labels
      ctx =
        Enum.reduce(sub_ids, ctx, fn id, ctx ->
          Context.update_blossom(ctx, id, label: :none)
        end)

      # Expand the T-blossom
      ctx = BlossomOps.expand_t_blossom(ctx, blossom.id)

      # Check that sub-blossoms have alternating labels
      # Entry point is vertex 0, so its blossom gets T
      id0 = Context.get_trivial_blossom_id(ctx, 0)
      b0 = Context.get_blossom(ctx, id0)
      assert b0.label == :t
      assert b0.tree_edge == {3, 0}
    end

    test "raises when blossom is not T-labeled" do
      graph = Graph.new([{0, 1, 10}, {1, 2, 10}, {2, 0, 10}])
      ctx = Context.new(graph)

      ctx =
        Enum.reduce(0..2, ctx, fn v, ctx ->
          id = Context.get_vertex_blossom_id(ctx, v)
          Context.update_blossom(ctx, id, label: :s)
        end)

      path = %AlternatingPath{edges: [{0, 1}, {1, 2}, {2, 0}]}
      ctx = BlossomOps.make_blossom(ctx, path)

      blossom = Context.get_vertex_blossom(ctx, 0)

      # Blossom is labeled :s, should fail
      assert_raise ArgumentError, ~r/must be T-labeled/, fn ->
        BlossomOps.expand_t_blossom(ctx, blossom.id)
      end
    end

    test "removes expanded blossom from context" do
      graph =
        Graph.new([
          {0, 1, 10},
          {1, 2, 10},
          {2, 0, 10},
          {0, 3, 10}
        ])

      ctx = Context.new(graph)

      ctx =
        Enum.reduce(0..3, ctx, fn v, ctx ->
          id = Context.get_vertex_blossom_id(ctx, v)
          Context.update_blossom(ctx, id, label: :s)
        end)

      path = %AlternatingPath{edges: [{0, 1}, {1, 2}, {2, 0}]}
      ctx = BlossomOps.make_blossom(ctx, path)

      blossom = Context.get_vertex_blossom(ctx, 0)
      sub_ids = blossom.subblossom_ids

      ctx = Context.update_blossom(ctx, blossom.id, label: :t, tree_edge: {3, 0})

      ctx =
        Enum.reduce(sub_ids, ctx, fn id, ctx ->
          Context.update_blossom(ctx, id, label: :none)
        end)

      ctx = BlossomOps.expand_t_blossom(ctx, blossom.id)

      # Blossom should be removed
      assert_raise KeyError, fn ->
        Context.get_blossom(ctx, blossom.id)
      end
    end
  end
end
