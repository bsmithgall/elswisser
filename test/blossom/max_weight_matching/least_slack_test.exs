defmodule Blossom.MaxWeightMatching.LeastSlackTest do
  use ExUnit.Case, async: true

  alias Blossom.MaxWeightMatching.Blossom.NonTrivial
  alias Blossom.MaxWeightMatching.Blossom.Trivial
  alias Blossom.MaxWeightMatching.Context
  alias Blossom.MaxWeightMatching.Graph
  alias Blossom.MaxWeightMatching.LeastSlack
  alias Blossom.MaxWeightMatching.Slack

  # Helper to create a context with labeled blossoms
  defp label_blossom(ctx, vertex, label) do
    blossom_id = Context.get_vertex_blossom_id(ctx, vertex)
    Context.update_blossom(ctx, blossom_id, label: label)
  end

  describe "reset/1" do
    test "resets vertex_best_edge to -1 for all vertices" do
      graph = Graph.new([{0, 1, 5}, {1, 2, 3}])
      ctx = Context.new(graph)

      # Manually set some best edges
      ctx = %{ctx | vertex_best_edge: %{0 => 0, 1 => 1, 2 => 0}}

      ctx = LeastSlack.reset(ctx)

      assert ctx.vertex_best_edge[0] == -1
      assert ctx.vertex_best_edge[1] == -1
      assert ctx.vertex_best_edge[2] == -1
    end

    test "resets best_edge to -1 for trivial blossoms" do
      graph = Graph.new([{0, 1, 5}])
      ctx = Context.new(graph)

      # Set a best_edge on a trivial blossom
      blossom_id = Context.get_vertex_blossom_id(ctx, 0)
      ctx = Context.update_blossom(ctx, blossom_id, best_edge: 0)

      ctx = LeastSlack.reset(ctx)

      blossom = Context.get_blossom(ctx, blossom_id)
      assert blossom.best_edge == -1
    end

    test "resets best_edge and best_edge_set for non-trivial blossoms" do
      graph = Graph.new([{0, 1, 5}, {1, 2, 5}, {0, 2, 5}])
      ctx = Context.new(graph)

      # Create a non-trivial blossom containing vertices 0, 1, 2
      sub_ids = [
        Context.get_vertex_blossom_id(ctx, 0),
        Context.get_vertex_blossom_id(ctx, 1),
        Context.get_vertex_blossom_id(ctx, 2)
      ]

      nt_blossom = NonTrivial.new(sub_ids, [{0, 1}, {1, 2}, {2, 0}], 0)
      nt_blossom = %{nt_blossom | best_edge: 0, best_edge_set: [0, 1, 2]}
      ctx = Context.add_blossom(ctx, nt_blossom)

      ctx = LeastSlack.reset(ctx)

      blossom = Context.get_blossom(ctx, nt_blossom.id)
      assert blossom.best_edge == -1
      assert blossom.best_edge_set == nil
    end
  end

  describe "add_vertex_edge/4" do
    test "stores first edge for vertex" do
      graph = Graph.new([{0, 1, 5}, {0, 2, 3}])
      ctx = Context.new(graph)
      ctx = LeastSlack.reset(ctx)

      slack = Slack.edge_slack_2x(ctx, 0)
      ctx = LeastSlack.add_vertex_edge(ctx, 1, 0, slack)

      assert ctx.vertex_best_edge[1] == 0
    end

    test "replaces edge when new edge has less slack" do
      # Edge 0: {0, 1, 5} -> slack = 0
      # Edge 1: {0, 2, 3} -> slack = 4
      # Edge 2: {1, 2, 4} -> slack = 2
      graph = Graph.new([{0, 1, 5}, {0, 2, 3}, {1, 2, 4}])
      ctx = Context.new(graph)
      ctx = LeastSlack.reset(ctx)

      # Add edge 1 (slack 4) first
      slack1 = Slack.edge_slack_2x(ctx, 1)
      ctx = LeastSlack.add_vertex_edge(ctx, 2, 1, slack1)
      assert ctx.vertex_best_edge[2] == 1

      # Add edge 2 (slack 2) - should replace
      slack2 = Slack.edge_slack_2x(ctx, 2)
      ctx = LeastSlack.add_vertex_edge(ctx, 2, 2, slack2)
      assert ctx.vertex_best_edge[2] == 2
    end

    test "keeps current edge when new edge has more slack" do
      graph = Graph.new([{0, 1, 5}, {0, 2, 3}, {1, 2, 4}])
      ctx = Context.new(graph)
      ctx = LeastSlack.reset(ctx)

      # Add edge 2 (slack 2) first
      slack2 = Slack.edge_slack_2x(ctx, 2)
      ctx = LeastSlack.add_vertex_edge(ctx, 2, 2, slack2)

      # Add edge 1 (slack 4) - should NOT replace
      slack1 = Slack.edge_slack_2x(ctx, 1)
      ctx = LeastSlack.add_vertex_edge(ctx, 2, 1, slack1)
      assert ctx.vertex_best_edge[2] == 2
    end
  end

  describe "get_best_vertex_edge/1" do
    test "returns best edge among unlabeled vertices" do
      graph = Graph.new([{0, 1, 5}, {0, 2, 3}])
      ctx = Context.new(graph)
      ctx = LeastSlack.reset(ctx)

      # Add edges to vertices 1 and 2
      slack0 = Slack.edge_slack_2x(ctx, 0)
      slack1 = Slack.edge_slack_2x(ctx, 1)
      ctx = LeastSlack.add_vertex_edge(ctx, 1, 0, slack0)
      ctx = LeastSlack.add_vertex_edge(ctx, 2, 1, slack1)

      # Edge 0 has slack 0, edge 1 has slack 4
      {edge, slack} = LeastSlack.get_best_vertex_edge(ctx)
      assert edge == 0
      assert slack == 0
    end

    test "ignores S-labeled vertices" do
      graph = Graph.new([{0, 1, 5}, {0, 2, 3}])
      ctx = Context.new(graph)
      ctx = LeastSlack.reset(ctx)

      slack0 = Slack.edge_slack_2x(ctx, 0)
      slack1 = Slack.edge_slack_2x(ctx, 1)
      ctx = LeastSlack.add_vertex_edge(ctx, 1, 0, slack0)
      ctx = LeastSlack.add_vertex_edge(ctx, 2, 1, slack1)

      # Label vertex 1's blossom as S
      ctx = label_blossom(ctx, 1, :s)

      # Should only find edge 1 (to vertex 2)
      {edge, slack} = LeastSlack.get_best_vertex_edge(ctx)
      assert edge == 1
      assert slack == 4
    end

    test "ignores T-labeled vertices" do
      graph = Graph.new([{0, 1, 5}, {0, 2, 3}])
      ctx = Context.new(graph)
      ctx = LeastSlack.reset(ctx)

      slack0 = Slack.edge_slack_2x(ctx, 0)
      slack1 = Slack.edge_slack_2x(ctx, 1)
      ctx = LeastSlack.add_vertex_edge(ctx, 1, 0, slack0)
      ctx = LeastSlack.add_vertex_edge(ctx, 2, 1, slack1)

      # Label vertex 1's blossom as T
      ctx = label_blossom(ctx, 1, :t)

      {edge, _slack} = LeastSlack.get_best_vertex_edge(ctx)
      assert edge == 1
    end

    test "returns {-1, 0} when no unlabeled vertices have edges" do
      graph = Graph.new([{0, 1, 5}])
      ctx = Context.new(graph)
      ctx = LeastSlack.reset(ctx)

      # Label all vertices as S
      ctx = label_blossom(ctx, 0, :s)
      ctx = label_blossom(ctx, 1, :s)

      assert LeastSlack.get_best_vertex_edge(ctx) == {-1, 0}
    end

    test "returns {-1, 0} when no edges tracked" do
      graph = Graph.new([{0, 1, 5}])
      ctx = Context.new(graph)
      ctx = LeastSlack.reset(ctx)

      assert LeastSlack.get_best_vertex_edge(ctx) == {-1, 0}
    end
  end

  describe "new_blossom/2" do
    test "does nothing for trivial blossom" do
      graph = Graph.new([{0, 1, 5}])
      ctx = Context.new(graph)

      blossom_id = Context.get_vertex_blossom_id(ctx, 0)
      ctx_after = LeastSlack.new_blossom(ctx, blossom_id)

      blossom = Context.get_blossom(ctx_after, blossom_id)
      assert %Trivial{} = blossom
      assert blossom.best_edge == -1
    end

    test "initializes best_edge_set to empty list for non-trivial blossom" do
      graph = Graph.new([{0, 1, 5}, {1, 2, 5}, {0, 2, 5}])
      ctx = Context.new(graph)

      sub_ids = [
        Context.get_vertex_blossom_id(ctx, 0),
        Context.get_vertex_blossom_id(ctx, 1),
        Context.get_vertex_blossom_id(ctx, 2)
      ]

      nt_blossom = NonTrivial.new(sub_ids, [{0, 1}, {1, 2}, {2, 0}], 0)
      ctx = Context.add_blossom(ctx, nt_blossom)

      ctx = LeastSlack.new_blossom(ctx, nt_blossom.id)

      blossom = Context.get_blossom(ctx, nt_blossom.id)
      assert blossom.best_edge_set == []
    end

    test "raises if best_edge is not -1" do
      graph = Graph.new([{0, 1, 5}])
      ctx = Context.new(graph)

      blossom_id = Context.get_vertex_blossom_id(ctx, 0)
      ctx = Context.update_blossom(ctx, blossom_id, best_edge: 0)

      assert_raise ArgumentError, ~r/best_edge must be -1/, fn ->
        LeastSlack.new_blossom(ctx, blossom_id)
      end
    end

    test "raises if best_edge_set is not nil for non-trivial blossom" do
      graph = Graph.new([{0, 1, 5}, {1, 2, 5}, {0, 2, 5}])
      ctx = Context.new(graph)

      sub_ids = [
        Context.get_vertex_blossom_id(ctx, 0),
        Context.get_vertex_blossom_id(ctx, 1),
        Context.get_vertex_blossom_id(ctx, 2)
      ]

      nt_blossom = NonTrivial.new(sub_ids, [{0, 1}, {1, 2}, {2, 0}], 0)
      nt_blossom = %{nt_blossom | best_edge_set: []}
      ctx = Context.add_blossom(ctx, nt_blossom)

      assert_raise ArgumentError, ~r/best_edge_set must be nil/, fn ->
        LeastSlack.new_blossom(ctx, nt_blossom.id)
      end
    end
  end

  describe "add_blossom_edge/4" do
    test "stores first edge for trivial blossom" do
      graph = Graph.new([{0, 1, 5}, {0, 2, 3}])
      ctx = Context.new(graph)
      ctx = LeastSlack.reset(ctx)

      blossom_id = Context.get_vertex_blossom_id(ctx, 0)
      slack = Slack.edge_slack_2x(ctx, 0)
      ctx = LeastSlack.add_blossom_edge(ctx, blossom_id, 0, slack)

      blossom = Context.get_blossom(ctx, blossom_id)
      assert blossom.best_edge == 0
    end

    test "replaces edge with less slack for trivial blossom" do
      graph = Graph.new([{0, 1, 5}, {0, 2, 3}])
      ctx = Context.new(graph)
      ctx = LeastSlack.reset(ctx)

      blossom_id = Context.get_vertex_blossom_id(ctx, 0)

      # Add edge 1 (slack 4) first
      slack1 = Slack.edge_slack_2x(ctx, 1)
      ctx = LeastSlack.add_blossom_edge(ctx, blossom_id, 1, slack1)

      # Add edge 0 (slack 0) - should replace
      slack0 = Slack.edge_slack_2x(ctx, 0)
      ctx = LeastSlack.add_blossom_edge(ctx, blossom_id, 0, slack0)

      blossom = Context.get_blossom(ctx, blossom_id)
      assert blossom.best_edge == 0
    end

    test "appends to best_edge_set for non-trivial blossom" do
      graph = Graph.new([{0, 1, 5}, {1, 2, 5}, {0, 2, 5}, {2, 3, 3}])
      ctx = Context.new(graph)

      sub_ids = [
        Context.get_vertex_blossom_id(ctx, 0),
        Context.get_vertex_blossom_id(ctx, 1),
        Context.get_vertex_blossom_id(ctx, 2)
      ]

      nt_blossom = NonTrivial.new(sub_ids, [{0, 1}, {1, 2}, {2, 0}], 0)
      ctx = Context.add_blossom(ctx, nt_blossom)
      ctx = LeastSlack.new_blossom(ctx, nt_blossom.id)

      # Add edge 3 (connects to vertex 3)
      slack = Slack.edge_slack_2x(ctx, 3)
      ctx = LeastSlack.add_blossom_edge(ctx, nt_blossom.id, 3, slack)

      blossom = Context.get_blossom(ctx, nt_blossom.id)
      assert blossom.best_edge == 3
      assert 3 in blossom.best_edge_set
    end

    test "accumulates edges in best_edge_set for non-trivial blossom" do
      graph = Graph.new([{0, 1, 5}, {1, 2, 5}, {0, 2, 5}, {2, 3, 3}, {0, 4, 4}])
      ctx = Context.new(graph)

      sub_ids = [
        Context.get_vertex_blossom_id(ctx, 0),
        Context.get_vertex_blossom_id(ctx, 1),
        Context.get_vertex_blossom_id(ctx, 2)
      ]

      nt_blossom = NonTrivial.new(sub_ids, [{0, 1}, {1, 2}, {2, 0}], 0)
      ctx = Context.add_blossom(ctx, nt_blossom)
      ctx = LeastSlack.new_blossom(ctx, nt_blossom.id)

      slack3 = Slack.edge_slack_2x(ctx, 3)
      slack4 = Slack.edge_slack_2x(ctx, 4)
      ctx = LeastSlack.add_blossom_edge(ctx, nt_blossom.id, 3, slack3)
      ctx = LeastSlack.add_blossom_edge(ctx, nt_blossom.id, 4, slack4)

      blossom = Context.get_blossom(ctx, nt_blossom.id)
      assert 3 in blossom.best_edge_set
      assert 4 in blossom.best_edge_set
    end
  end

  describe "get_best_blossom_edge/1" do
    test "returns best edge among S-blossoms" do
      graph = Graph.new([{0, 1, 5}, {0, 2, 3}])
      ctx = Context.new(graph)
      ctx = LeastSlack.reset(ctx)

      # Label blossoms as S
      ctx = label_blossom(ctx, 0, :s)
      ctx = label_blossom(ctx, 1, :s)

      # Add edge to blossom 0
      blossom_id = Context.get_vertex_blossom_id(ctx, 0)
      slack = Slack.edge_slack_2x(ctx, 0)
      ctx = LeastSlack.add_blossom_edge(ctx, blossom_id, 0, slack)

      {edge, edge_slack} = LeastSlack.get_best_blossom_edge(ctx)
      assert edge == 0
      assert edge_slack == 0
    end

    test "ignores non-S blossoms" do
      graph = Graph.new([{0, 1, 5}, {1, 2, 3}])
      ctx = Context.new(graph)
      ctx = LeastSlack.reset(ctx)

      # Vertex 0 is S, vertex 1 is T, vertex 2 is unlabeled
      ctx = label_blossom(ctx, 0, :s)
      ctx = label_blossom(ctx, 1, :t)

      # Add edge to both blossoms
      blossom0 = Context.get_vertex_blossom_id(ctx, 0)
      blossom1 = Context.get_vertex_blossom_id(ctx, 1)

      slack0 = Slack.edge_slack_2x(ctx, 0)
      slack1 = Slack.edge_slack_2x(ctx, 1)
      ctx = LeastSlack.add_blossom_edge(ctx, blossom0, 0, slack0)
      ctx = LeastSlack.add_blossom_edge(ctx, blossom1, 1, slack1)

      # Should only return edge from S-blossom
      {edge, _slack} = LeastSlack.get_best_blossom_edge(ctx)
      assert edge == 0
    end

    test "ignores nested blossoms (parent_id != nil)" do
      graph = Graph.new([{0, 1, 5}, {1, 2, 5}, {0, 2, 5}, {2, 3, 3}])
      ctx = Context.new(graph)

      # Get sub-blossom IDs
      sub0_id = Context.get_vertex_blossom_id(ctx, 0)
      sub1_id = Context.get_vertex_blossom_id(ctx, 1)
      sub2_id = Context.get_vertex_blossom_id(ctx, 2)

      # Create non-trivial blossom
      nt_blossom = NonTrivial.new([sub0_id, sub1_id, sub2_id], [{0, 1}, {1, 2}, {2, 0}], 0)
      ctx = Context.add_blossom(ctx, nt_blossom)

      # Set parent_id on sub-blossoms
      ctx = Context.update_blossom(ctx, sub0_id, parent_id: nt_blossom.id, label: :s)
      ctx = Context.update_blossom(ctx, sub1_id, parent_id: nt_blossom.id, label: :s)
      ctx = Context.update_blossom(ctx, sub2_id, parent_id: nt_blossom.id, label: :s)

      # Label non-trivial blossom as S
      ctx = Context.update_blossom(ctx, nt_blossom.id, label: :s)

      ctx = LeastSlack.reset(ctx)
      ctx = LeastSlack.new_blossom(ctx, nt_blossom.id)

      # Add edge only to a sub-blossom (which has parent_id set)
      slack = Slack.edge_slack_2x(ctx, 3)
      ctx = LeastSlack.add_blossom_edge(ctx, sub0_id, 3, slack)

      # Should not find any edge (sub-blossoms are nested)
      {edge, _slack} = LeastSlack.get_best_blossom_edge(ctx)
      assert edge == -1
    end

    test "returns {-1, 0} when no S-blossoms have edges" do
      graph = Graph.new([{0, 1, 5}])
      ctx = Context.new(graph)
      ctx = LeastSlack.reset(ctx)

      ctx = label_blossom(ctx, 0, :s)
      ctx = label_blossom(ctx, 1, :s)

      assert LeastSlack.get_best_blossom_edge(ctx) == {-1, 0}
    end

    test "finds minimum slack across multiple S-blossoms" do
      graph = Graph.new([{0, 1, 5}, {2, 3, 3}])
      ctx = Context.new(graph)
      ctx = LeastSlack.reset(ctx)

      # Label all as S
      ctx = label_blossom(ctx, 0, :s)
      ctx = label_blossom(ctx, 1, :s)
      ctx = label_blossom(ctx, 2, :s)
      ctx = label_blossom(ctx, 3, :s)

      blossom0 = Context.get_vertex_blossom_id(ctx, 0)
      blossom2 = Context.get_vertex_blossom_id(ctx, 2)

      # Edge 0 has slack 0, edge 1 has slack 4
      slack0 = Slack.edge_slack_2x(ctx, 0)
      slack1 = Slack.edge_slack_2x(ctx, 1)
      ctx = LeastSlack.add_blossom_edge(ctx, blossom0, 0, slack0)
      ctx = LeastSlack.add_blossom_edge(ctx, blossom2, 1, slack1)

      {edge, slack} = LeastSlack.get_best_blossom_edge(ctx)
      assert edge == 0
      assert slack == 0
    end
  end

  describe "merge_blossoms/2" do
    test "merges edge sets from trivial S-sub-blossoms" do
      # Graph: triangle (0-1-2) with external vertex 3 connected to vertex 2
      #   0---1
      #    \ /
      #     2---3
      graph = Graph.new([{0, 1, 5}, {1, 2, 5}, {0, 2, 5}, {2, 3, 5}])
      ctx = Context.new(graph)
      ctx = LeastSlack.reset(ctx)

      # Get sub-blossom IDs and label them as S
      id0 = Context.get_vertex_blossom_id(ctx, 0)
      id1 = Context.get_vertex_blossom_id(ctx, 1)
      id2 = Context.get_vertex_blossom_id(ctx, 2)
      id3 = Context.get_vertex_blossom_id(ctx, 3)

      ctx = Context.update_blossom(ctx, id0, label: :s)
      ctx = Context.update_blossom(ctx, id1, label: :s)
      ctx = Context.update_blossom(ctx, id2, label: :s)
      ctx = Context.update_blossom(ctx, id3, label: :s)

      # Create non-trivial blossom from 0, 1, 2
      nt_blossom = NonTrivial.new([id0, id1, id2], [{0, 1}, {1, 2}, {2, 0}], 0)
      nt_blossom = %{nt_blossom | label: :s}
      ctx = Context.add_blossom(ctx, nt_blossom)

      # Update parent_id for sub-blossoms
      ctx = Context.update_blossom(ctx, id0, parent_id: nt_blossom.id)
      ctx = Context.update_blossom(ctx, id1, parent_id: nt_blossom.id)
      ctx = Context.update_blossom(ctx, id2, parent_id: nt_blossom.id)

      # Update vertex mappings
      ctx = Context.set_vertices_blossom(ctx, [0, 1, 2], nt_blossom.id)

      # Merge blossoms
      ctx = LeastSlack.merge_blossoms(ctx, nt_blossom.id)

      blossom = Context.get_blossom(ctx, nt_blossom.id)

      # Edge 3 (2-3) connects to external S-blossom, should be in best_edge_set
      assert blossom.best_edge == 3
      assert 3 in blossom.best_edge_set
    end

    test "filters out internal edges" do
      # All edges are internal to the new blossom
      graph = Graph.new([{0, 1, 5}, {1, 2, 5}, {0, 2, 5}])
      ctx = Context.new(graph)
      ctx = LeastSlack.reset(ctx)

      id0 = Context.get_vertex_blossom_id(ctx, 0)
      id1 = Context.get_vertex_blossom_id(ctx, 1)
      id2 = Context.get_vertex_blossom_id(ctx, 2)

      ctx = Context.update_blossom(ctx, id0, label: :s)
      ctx = Context.update_blossom(ctx, id1, label: :s)
      ctx = Context.update_blossom(ctx, id2, label: :s)

      nt_blossom = NonTrivial.new([id0, id1, id2], [{0, 1}, {1, 2}, {2, 0}], 0)
      nt_blossom = %{nt_blossom | label: :s}
      ctx = Context.add_blossom(ctx, nt_blossom)

      ctx = Context.update_blossom(ctx, id0, parent_id: nt_blossom.id)
      ctx = Context.update_blossom(ctx, id1, parent_id: nt_blossom.id)
      ctx = Context.update_blossom(ctx, id2, parent_id: nt_blossom.id)

      ctx = Context.set_vertices_blossom(ctx, [0, 1, 2], nt_blossom.id)

      ctx = LeastSlack.merge_blossoms(ctx, nt_blossom.id)

      blossom = Context.get_blossom(ctx, nt_blossom.id)

      # No external edges, so best_edge should be -1
      assert blossom.best_edge == -1
      assert blossom.best_edge_set == []
    end

    test "filters out edges to non-S blossoms" do
      # Triangle with external unlabeled vertex
      graph = Graph.new([{0, 1, 5}, {1, 2, 5}, {0, 2, 5}, {2, 3, 5}])
      ctx = Context.new(graph)
      ctx = LeastSlack.reset(ctx)

      id0 = Context.get_vertex_blossom_id(ctx, 0)
      id1 = Context.get_vertex_blossom_id(ctx, 1)
      id2 = Context.get_vertex_blossom_id(ctx, 2)
      # id3 stays unlabeled (label: :none)

      ctx = Context.update_blossom(ctx, id0, label: :s)
      ctx = Context.update_blossom(ctx, id1, label: :s)
      ctx = Context.update_blossom(ctx, id2, label: :s)

      nt_blossom = NonTrivial.new([id0, id1, id2], [{0, 1}, {1, 2}, {2, 0}], 0)
      nt_blossom = %{nt_blossom | label: :s}
      ctx = Context.add_blossom(ctx, nt_blossom)

      ctx = Context.update_blossom(ctx, id0, parent_id: nt_blossom.id)
      ctx = Context.update_blossom(ctx, id1, parent_id: nt_blossom.id)
      ctx = Context.update_blossom(ctx, id2, parent_id: nt_blossom.id)

      ctx = Context.set_vertices_blossom(ctx, [0, 1, 2], nt_blossom.id)

      ctx = LeastSlack.merge_blossoms(ctx, nt_blossom.id)

      blossom = Context.get_blossom(ctx, nt_blossom.id)

      # Edge to unlabeled vertex is filtered out
      assert blossom.best_edge == -1
      assert blossom.best_edge_set == []
    end

    test "ignores T-labeled sub-blossoms" do
      # Triangle where one sub-blossom is labeled T
      graph = Graph.new([{0, 1, 5}, {1, 2, 5}, {0, 2, 5}, {2, 3, 5}])
      ctx = Context.new(graph)
      ctx = LeastSlack.reset(ctx)

      id0 = Context.get_vertex_blossom_id(ctx, 0)
      id1 = Context.get_vertex_blossom_id(ctx, 1)
      id2 = Context.get_vertex_blossom_id(ctx, 2)
      id3 = Context.get_vertex_blossom_id(ctx, 3)

      # 0 and 1 are S, 2 is T (so its edges won't be scanned)
      ctx = Context.update_blossom(ctx, id0, label: :s)
      ctx = Context.update_blossom(ctx, id1, label: :s)
      ctx = Context.update_blossom(ctx, id2, label: :t)
      ctx = Context.update_blossom(ctx, id3, label: :s)

      nt_blossom = NonTrivial.new([id0, id1, id2], [{0, 1}, {1, 2}, {2, 0}], 0)
      nt_blossom = %{nt_blossom | label: :s}
      ctx = Context.add_blossom(ctx, nt_blossom)

      ctx = Context.update_blossom(ctx, id0, parent_id: nt_blossom.id)
      ctx = Context.update_blossom(ctx, id1, parent_id: nt_blossom.id)
      ctx = Context.update_blossom(ctx, id2, parent_id: nt_blossom.id)

      ctx = Context.set_vertices_blossom(ctx, [0, 1, 2], nt_blossom.id)

      ctx = LeastSlack.merge_blossoms(ctx, nt_blossom.id)

      blossom = Context.get_blossom(ctx, nt_blossom.id)

      # Edge 2-3 is from T-sub-blossom, so it's ignored
      # Only edges from S-sub-blossoms (0, 1) are considered
      # 0's edges: 0-1 (internal), 0-2 (internal)
      # 1's edges: 0-1 (internal), 1-2 (internal)
      # No external S-edges from S-sub-blossoms
      assert blossom.best_edge == -1
    end

    test "handles non-trivial sub-blossoms with edge sets" do
      # Create a nested structure: outer blossom contains a non-trivial sub-blossom
      # Graph: 0-1-2 (inner triangle) + 3-4-5 (outer) + edge 2-3
      graph =
        Graph.new([
          {0, 1, 5},
          {1, 2, 5},
          {0, 2, 5},
          {3, 4, 5},
          {4, 5, 5},
          {3, 5, 5},
          {2, 3, 5}
        ])

      ctx = Context.new(graph)
      ctx = LeastSlack.reset(ctx)

      # Create inner non-trivial blossom from 0, 1, 2
      id0 = Context.get_vertex_blossom_id(ctx, 0)
      id1 = Context.get_vertex_blossom_id(ctx, 1)
      id2 = Context.get_vertex_blossom_id(ctx, 2)
      id3 = Context.get_vertex_blossom_id(ctx, 3)
      id4 = Context.get_vertex_blossom_id(ctx, 4)
      id5 = Context.get_vertex_blossom_id(ctx, 5)

      # Label all as S
      ctx = Context.update_blossom(ctx, id0, label: :s)
      ctx = Context.update_blossom(ctx, id1, label: :s)
      ctx = Context.update_blossom(ctx, id2, label: :s)
      ctx = Context.update_blossom(ctx, id3, label: :s)
      ctx = Context.update_blossom(ctx, id4, label: :s)
      ctx = Context.update_blossom(ctx, id5, label: :s)

      inner_blossom = NonTrivial.new([id0, id1, id2], [{0, 1}, {1, 2}, {2, 0}], 0)
      inner_blossom = %{inner_blossom | label: :s, best_edge_set: [6]}
      ctx = Context.add_blossom(ctx, inner_blossom)

      ctx = Context.update_blossom(ctx, id0, parent_id: inner_blossom.id)
      ctx = Context.update_blossom(ctx, id1, parent_id: inner_blossom.id)
      ctx = Context.update_blossom(ctx, id2, parent_id: inner_blossom.id)

      ctx = Context.set_vertices_blossom(ctx, [0, 1, 2], inner_blossom.id)

      # Create outer blossom containing inner_blossom, id3, id4, id5
      # This is a bit artificial but tests the code path
      outer_blossom =
        NonTrivial.new(
          [inner_blossom.id, id3, id5],
          [{2, 3}, {3, 5}, {5, 0}],
          0
        )

      outer_blossom = %{outer_blossom | label: :s}
      ctx = Context.add_blossom(ctx, outer_blossom)

      ctx = Context.update_blossom(ctx, inner_blossom.id, parent_id: outer_blossom.id)
      ctx = Context.update_blossom(ctx, id3, parent_id: outer_blossom.id)
      ctx = Context.update_blossom(ctx, id5, parent_id: outer_blossom.id)

      ctx = Context.set_vertices_blossom(ctx, [0, 1, 2, 3, 5], outer_blossom.id)

      ctx = LeastSlack.merge_blossoms(ctx, outer_blossom.id)

      # The inner blossom's best_edge_set should have been cleared
      inner = Context.get_blossom(ctx, inner_blossom.id)
      assert inner.best_edge_set == nil
    end

    test "keeps best edge per external S-blossom" do
      # Graph: triangle (0-1-2) with two edges to same external vertex 3
      # Edge 3: 0-3 (weight 10), Edge 4: 2-3 (weight 3)
      # Initial duals = max_weight = 10
      # Slack for edge 3 (weight 10): 10 + 10 - 20 = 0
      # Slack for edge 4 (weight 3): 10 + 10 - 6 = 14
      # Edge 3 has LESS slack, so it should be kept
      graph = Graph.new([{0, 1, 5}, {1, 2, 5}, {0, 2, 5}, {0, 3, 10}, {2, 3, 3}])
      ctx = Context.new(graph)
      ctx = LeastSlack.reset(ctx)

      id0 = Context.get_vertex_blossom_id(ctx, 0)
      id1 = Context.get_vertex_blossom_id(ctx, 1)
      id2 = Context.get_vertex_blossom_id(ctx, 2)
      id3 = Context.get_vertex_blossom_id(ctx, 3)

      ctx = Context.update_blossom(ctx, id0, label: :s)
      ctx = Context.update_blossom(ctx, id1, label: :s)
      ctx = Context.update_blossom(ctx, id2, label: :s)
      ctx = Context.update_blossom(ctx, id3, label: :s)

      nt_blossom = NonTrivial.new([id0, id1, id2], [{0, 1}, {1, 2}, {2, 0}], 0)
      nt_blossom = %{nt_blossom | label: :s}
      ctx = Context.add_blossom(ctx, nt_blossom)

      ctx = Context.update_blossom(ctx, id0, parent_id: nt_blossom.id)
      ctx = Context.update_blossom(ctx, id1, parent_id: nt_blossom.id)
      ctx = Context.update_blossom(ctx, id2, parent_id: nt_blossom.id)

      ctx = Context.set_vertices_blossom(ctx, [0, 1, 2], nt_blossom.id)

      ctx = LeastSlack.merge_blossoms(ctx, nt_blossom.id)

      blossom = Context.get_blossom(ctx, nt_blossom.id)

      # Edge 3 (0-3, weight 10) has less slack (0) than edge 4 (2-3, weight 3) (slack 14)
      # So only edge 3 should be kept for blossom 3
      assert length(blossom.best_edge_set) == 1
      assert 3 in blossom.best_edge_set
      assert blossom.best_edge == 3
    end

    test "sets best_edge to minimum slack among all external edges" do
      # Graph: triangle (0-1-2) with edges to two different external vertices
      # Edge 3: 0-3 (weight 10), Edge 4: 2-4 (weight 3)
      # Initial duals = max_weight = 10
      # Slack for edge 3 (weight 10): 10 + 10 - 20 = 0
      # Slack for edge 4 (weight 3): 10 + 10 - 6 = 14
      # Edge 3 has LESS slack (0), so it's the best_edge
      graph = Graph.new([{0, 1, 5}, {1, 2, 5}, {0, 2, 5}, {0, 3, 10}, {2, 4, 3}])
      ctx = Context.new(graph)
      ctx = LeastSlack.reset(ctx)

      id0 = Context.get_vertex_blossom_id(ctx, 0)
      id1 = Context.get_vertex_blossom_id(ctx, 1)
      id2 = Context.get_vertex_blossom_id(ctx, 2)
      id3 = Context.get_vertex_blossom_id(ctx, 3)
      id4 = Context.get_vertex_blossom_id(ctx, 4)

      ctx = Context.update_blossom(ctx, id0, label: :s)
      ctx = Context.update_blossom(ctx, id1, label: :s)
      ctx = Context.update_blossom(ctx, id2, label: :s)
      ctx = Context.update_blossom(ctx, id3, label: :s)
      ctx = Context.update_blossom(ctx, id4, label: :s)

      nt_blossom = NonTrivial.new([id0, id1, id2], [{0, 1}, {1, 2}, {2, 0}], 0)
      nt_blossom = %{nt_blossom | label: :s}
      ctx = Context.add_blossom(ctx, nt_blossom)

      ctx = Context.update_blossom(ctx, id0, parent_id: nt_blossom.id)
      ctx = Context.update_blossom(ctx, id1, parent_id: nt_blossom.id)
      ctx = Context.update_blossom(ctx, id2, parent_id: nt_blossom.id)

      ctx = Context.set_vertices_blossom(ctx, [0, 1, 2], nt_blossom.id)

      ctx = LeastSlack.merge_blossoms(ctx, nt_blossom.id)

      blossom = Context.get_blossom(ctx, nt_blossom.id)

      # Both edges should be in best_edge_set (one to each external blossom)
      assert length(blossom.best_edge_set) == 2
      # Edge 3 (0-3, weight 10) has less slack (0), so it's the best_edge
      assert blossom.best_edge == 3
    end
  end
end
