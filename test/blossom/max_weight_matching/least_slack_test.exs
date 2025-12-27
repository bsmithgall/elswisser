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
end
