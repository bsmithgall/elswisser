defmodule MaxWeightMatching.LeastSlackTest do
  use ExUnit.Case, async: true

  alias MaxWeightMatching.Blossom.NonTrivial
  alias MaxWeightMatching.Blossom.Trivial
  alias MaxWeightMatching.Context
  alias MaxWeightMatching.Graph
  alias MaxWeightMatching.LeastSlack
  alias MaxWeightMatching.Slack

  # Helper to create a context with labeled blossoms
  defp label_blossom(ctx, vertex, label) do
    blossom_id = Context.get_vertex_blossom_id(ctx, vertex)
    Context.update_blossom(ctx, blossom_id, label: label)
  end

  describe "reset/1" do
    test "resets vertex_best_edge to -1 for all vertices" do
      ctx =
        [{0, 1, 5}, {1, 2, 3}]
        |> Graph.new()
        |> Context.new()
        |> then(&%{&1 | vertex_best_edge: %{0 => 0, 1 => 1, 2 => 0}})
        |> LeastSlack.reset()

      assert ctx.vertex_best_edge[0] == -1
      assert ctx.vertex_best_edge[1] == -1
      assert ctx.vertex_best_edge[2] == -1
    end

    test "resets best_edge to -1 for trivial blossoms" do
      graph = Graph.new([{0, 1, 5}])
      ctx = Context.new(graph)
      blossom_id = Context.get_vertex_blossom_id(ctx, 0)

      ctx =
        ctx
        |> Context.update_blossom(blossom_id, best_edge: 0)
        |> LeastSlack.reset()

      blossom = Context.get_blossom(ctx, blossom_id)
      assert blossom.best_edge == -1
    end

    test "resets best_edge and best_edge_set for non-trivial blossoms" do
      graph = Graph.new([{0, 1, 5}, {1, 2, 5}, {0, 2, 5}])
      ctx = Context.new(graph)

      sub_ids = [
        Context.get_vertex_blossom_id(ctx, 0),
        Context.get_vertex_blossom_id(ctx, 1),
        Context.get_vertex_blossom_id(ctx, 2)
      ]

      nt_blossom =
        sub_ids
        |> NonTrivial.new([{0, 1}, {1, 2}, {2, 0}], 0)
        |> then(&%{&1 | best_edge: 0, best_edge_set: [0, 1, 2]})

      ctx =
        ctx
        |> Context.add_blossom(nt_blossom)
        |> LeastSlack.reset()

      blossom = Context.get_blossom(ctx, nt_blossom.id)
      assert blossom.best_edge == -1
      assert blossom.best_edge_set == nil
    end
  end

  describe "add_vertex_edge/4" do
    test "stores first edge for vertex" do
      ctx =
        [{0, 1, 5}, {0, 2, 3}]
        |> Graph.new()
        |> Context.new()
        |> LeastSlack.reset()

      slack = Slack.edge_slack_2x(ctx, 0)
      ctx = LeastSlack.add_vertex_edge(ctx, 1, 0, slack)

      assert ctx.vertex_best_edge[1] == 0
    end

    test "replaces edge when new edge has less slack" do
      # Edge 0: {0, 1, 5} -> slack = 0
      # Edge 1: {0, 2, 3} -> slack = 4
      # Edge 2: {1, 2, 4} -> slack = 2
      ctx =
        [{0, 1, 5}, {0, 2, 3}, {1, 2, 4}]
        |> Graph.new()
        |> Context.new()
        |> LeastSlack.reset()

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
      ctx =
        [{0, 1, 5}, {0, 2, 3}, {1, 2, 4}]
        |> Graph.new()
        |> Context.new()
        |> LeastSlack.reset()

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
      ctx =
        [{0, 1, 5}, {0, 2, 3}]
        |> Graph.new()
        |> Context.new()
        |> LeastSlack.reset()

      slack0 = Slack.edge_slack_2x(ctx, 0)
      slack1 = Slack.edge_slack_2x(ctx, 1)

      ctx =
        ctx
        |> LeastSlack.add_vertex_edge(1, 0, slack0)
        |> LeastSlack.add_vertex_edge(2, 1, slack1)

      # Edge 0 has slack 0, edge 1 has slack 4
      {edge, slack} = LeastSlack.get_best_vertex_edge(ctx)
      assert edge == 0
      assert slack == 0
    end

    test "ignores S-labeled vertices" do
      ctx =
        [{0, 1, 5}, {0, 2, 3}]
        |> Graph.new()
        |> Context.new()
        |> LeastSlack.reset()

      slack0 = Slack.edge_slack_2x(ctx, 0)
      slack1 = Slack.edge_slack_2x(ctx, 1)

      ctx =
        ctx
        |> LeastSlack.add_vertex_edge(1, 0, slack0)
        |> LeastSlack.add_vertex_edge(2, 1, slack1)
        |> label_blossom(1, :s)

      # Should only find edge 1 (to vertex 2)
      {edge, slack} = LeastSlack.get_best_vertex_edge(ctx)
      assert edge == 1
      assert slack == 4
    end

    test "ignores T-labeled vertices" do
      ctx =
        [{0, 1, 5}, {0, 2, 3}]
        |> Graph.new()
        |> Context.new()
        |> LeastSlack.reset()

      slack0 = Slack.edge_slack_2x(ctx, 0)
      slack1 = Slack.edge_slack_2x(ctx, 1)

      ctx =
        ctx
        |> LeastSlack.add_vertex_edge(1, 0, slack0)
        |> LeastSlack.add_vertex_edge(2, 1, slack1)
        |> label_blossom(1, :t)

      {edge, _slack} = LeastSlack.get_best_vertex_edge(ctx)
      assert edge == 1
    end

    test "returns {-1, 0} when no unlabeled vertices have edges" do
      ctx =
        [{0, 1, 5}]
        |> Graph.new()
        |> Context.new()
        |> LeastSlack.reset()
        |> label_blossom(0, :s)
        |> label_blossom(1, :s)

      assert LeastSlack.get_best_vertex_edge(ctx) == {-1, 0}
    end

    test "returns {-1, 0} when no edges tracked" do
      ctx =
        [{0, 1, 5}]
        |> Graph.new()
        |> Context.new()
        |> LeastSlack.reset()

      assert LeastSlack.get_best_vertex_edge(ctx) == {-1, 0}
    end
  end

  describe "new_blossom/2" do
    test "does nothing for trivial blossom" do
      ctx =
        [{0, 1, 5}]
        |> Graph.new()
        |> Context.new()

      blossom_id = Context.get_vertex_blossom_id(ctx, 0)
      ctx_after = LeastSlack.new_blossom(ctx, blossom_id)

      blossom = Context.get_blossom(ctx_after, blossom_id)
      assert %Trivial{} = blossom
      assert blossom.best_edge == -1
    end

    test "initializes best_edge_set to empty list for non-trivial blossom" do
      ctx =
        [{0, 1, 5}, {1, 2, 5}, {0, 2, 5}]
        |> Graph.new()
        |> Context.new()

      sub_ids = [
        Context.get_vertex_blossom_id(ctx, 0),
        Context.get_vertex_blossom_id(ctx, 1),
        Context.get_vertex_blossom_id(ctx, 2)
      ]

      nt_blossom = NonTrivial.new(sub_ids, [{0, 1}, {1, 2}, {2, 0}], 0)

      ctx =
        ctx
        |> Context.add_blossom(nt_blossom)
        |> LeastSlack.new_blossom(nt_blossom.id)

      blossom = Context.get_blossom(ctx, nt_blossom.id)
      assert blossom.best_edge_set == []
    end

    test "raises if best_edge is not -1" do
      ctx =
        [{0, 1, 5}]
        |> Graph.new()
        |> Context.new()

      blossom_id = Context.get_vertex_blossom_id(ctx, 0)
      ctx = Context.update_blossom(ctx, blossom_id, best_edge: 0)

      assert_raise ArgumentError, ~r/best_edge must be -1/, fn ->
        LeastSlack.new_blossom(ctx, blossom_id)
      end
    end

    test "raises if best_edge_set is not nil for non-trivial blossom" do
      ctx =
        [{0, 1, 5}, {1, 2, 5}, {0, 2, 5}]
        |> Graph.new()
        |> Context.new()

      sub_ids = [
        Context.get_vertex_blossom_id(ctx, 0),
        Context.get_vertex_blossom_id(ctx, 1),
        Context.get_vertex_blossom_id(ctx, 2)
      ]

      nt_blossom =
        sub_ids
        |> NonTrivial.new([{0, 1}, {1, 2}, {2, 0}], 0)
        |> then(&%{&1 | best_edge_set: []})

      ctx = Context.add_blossom(ctx, nt_blossom)

      assert_raise ArgumentError, ~r/best_edge_set must be nil/, fn ->
        LeastSlack.new_blossom(ctx, nt_blossom.id)
      end
    end
  end

  describe "add_blossom_edge/4" do
    test "stores first edge for trivial blossom" do
      ctx =
        [{0, 1, 5}, {0, 2, 3}]
        |> Graph.new()
        |> Context.new()
        |> LeastSlack.reset()

      blossom_id = Context.get_vertex_blossom_id(ctx, 0)
      slack = Slack.edge_slack_2x(ctx, 0)
      ctx = LeastSlack.add_blossom_edge(ctx, blossom_id, 0, slack)

      blossom = Context.get_blossom(ctx, blossom_id)
      assert blossom.best_edge == 0
    end

    test "replaces edge with less slack for trivial blossom" do
      ctx =
        [{0, 1, 5}, {0, 2, 3}]
        |> Graph.new()
        |> Context.new()
        |> LeastSlack.reset()

      blossom_id = Context.get_vertex_blossom_id(ctx, 0)
      slack1 = Slack.edge_slack_2x(ctx, 1)
      slack0 = Slack.edge_slack_2x(ctx, 0)

      # Add edge 1 (slack 4) first, then edge 0 (slack 0) - should replace
      ctx =
        ctx
        |> LeastSlack.add_blossom_edge(blossom_id, 1, slack1)
        |> LeastSlack.add_blossom_edge(blossom_id, 0, slack0)

      blossom = Context.get_blossom(ctx, blossom_id)
      assert blossom.best_edge == 0
    end

    test "appends to best_edge_set for non-trivial blossom" do
      ctx =
        [{0, 1, 5}, {1, 2, 5}, {0, 2, 5}, {2, 3, 3}]
        |> Graph.new()
        |> Context.new()

      sub_ids = [
        Context.get_vertex_blossom_id(ctx, 0),
        Context.get_vertex_blossom_id(ctx, 1),
        Context.get_vertex_blossom_id(ctx, 2)
      ]

      nt_blossom = NonTrivial.new(sub_ids, [{0, 1}, {1, 2}, {2, 0}], 0)

      ctx =
        ctx
        |> Context.add_blossom(nt_blossom)
        |> LeastSlack.new_blossom(nt_blossom.id)

      slack = Slack.edge_slack_2x(ctx, 3)
      ctx = LeastSlack.add_blossom_edge(ctx, nt_blossom.id, 3, slack)

      blossom = Context.get_blossom(ctx, nt_blossom.id)
      assert blossom.best_edge == 3
      assert 3 in blossom.best_edge_set
    end

    test "accumulates edges in best_edge_set for non-trivial blossom" do
      ctx =
        [{0, 1, 5}, {1, 2, 5}, {0, 2, 5}, {2, 3, 3}, {0, 4, 4}]
        |> Graph.new()
        |> Context.new()

      sub_ids = [
        Context.get_vertex_blossom_id(ctx, 0),
        Context.get_vertex_blossom_id(ctx, 1),
        Context.get_vertex_blossom_id(ctx, 2)
      ]

      nt_blossom = NonTrivial.new(sub_ids, [{0, 1}, {1, 2}, {2, 0}], 0)

      ctx =
        ctx
        |> Context.add_blossom(nt_blossom)
        |> LeastSlack.new_blossom(nt_blossom.id)

      slack3 = Slack.edge_slack_2x(ctx, 3)
      slack4 = Slack.edge_slack_2x(ctx, 4)

      ctx =
        ctx
        |> LeastSlack.add_blossom_edge(nt_blossom.id, 3, slack3)
        |> LeastSlack.add_blossom_edge(nt_blossom.id, 4, slack4)

      blossom = Context.get_blossom(ctx, nt_blossom.id)
      assert 3 in blossom.best_edge_set
      assert 4 in blossom.best_edge_set
    end
  end

  describe "get_best_blossom_edge/1" do
    test "returns best edge among S-blossoms" do
      ctx =
        [{0, 1, 5}, {0, 2, 3}]
        |> Graph.new()
        |> Context.new()
        |> LeastSlack.reset()
        |> label_blossom(0, :s)
        |> label_blossom(1, :s)

      blossom_id = Context.get_vertex_blossom_id(ctx, 0)
      slack = Slack.edge_slack_2x(ctx, 0)
      ctx = LeastSlack.add_blossom_edge(ctx, blossom_id, 0, slack)

      {edge, edge_slack} = LeastSlack.get_best_blossom_edge(ctx)
      assert edge == 0
      assert edge_slack == 0
    end

    test "ignores non-S blossoms" do
      ctx =
        [{0, 1, 5}, {1, 2, 3}]
        |> Graph.new()
        |> Context.new()
        |> LeastSlack.reset()
        |> label_blossom(0, :s)
        |> label_blossom(1, :t)

      blossom0 = Context.get_vertex_blossom_id(ctx, 0)
      blossom1 = Context.get_vertex_blossom_id(ctx, 1)
      slack0 = Slack.edge_slack_2x(ctx, 0)
      slack1 = Slack.edge_slack_2x(ctx, 1)

      ctx =
        ctx
        |> LeastSlack.add_blossom_edge(blossom0, 0, slack0)
        |> LeastSlack.add_blossom_edge(blossom1, 1, slack1)

      # Should only return edge from S-blossom
      {edge, _slack} = LeastSlack.get_best_blossom_edge(ctx)
      assert edge == 0
    end

    test "ignores nested blossoms (parent_id != nil)" do
      ctx =
        [{0, 1, 5}, {1, 2, 5}, {0, 2, 5}, {2, 3, 3}]
        |> Graph.new()
        |> Context.new()

      sub0_id = Context.get_vertex_blossom_id(ctx, 0)
      sub1_id = Context.get_vertex_blossom_id(ctx, 1)
      sub2_id = Context.get_vertex_blossom_id(ctx, 2)

      nt_blossom = NonTrivial.new([sub0_id, sub1_id, sub2_id], [{0, 1}, {1, 2}, {2, 0}], 0)

      ctx =
        ctx
        |> Context.add_blossom(nt_blossom)
        |> Context.update_blossom(sub0_id, parent_id: nt_blossom.id, label: :s)
        |> Context.update_blossom(sub1_id, parent_id: nt_blossom.id, label: :s)
        |> Context.update_blossom(sub2_id, parent_id: nt_blossom.id, label: :s)
        |> Context.update_blossom(nt_blossom.id, label: :s)
        |> LeastSlack.reset()
        |> LeastSlack.new_blossom(nt_blossom.id)

      # Add edge only to a sub-blossom (which has parent_id set)
      slack = Slack.edge_slack_2x(ctx, 3)
      ctx = LeastSlack.add_blossom_edge(ctx, sub0_id, 3, slack)

      # Should not find any edge (sub-blossoms are nested)
      {edge, _slack} = LeastSlack.get_best_blossom_edge(ctx)
      assert edge == -1
    end

    test "returns {-1, 0} when no S-blossoms have edges" do
      ctx =
        [{0, 1, 5}]
        |> Graph.new()
        |> Context.new()
        |> LeastSlack.reset()
        |> label_blossom(0, :s)
        |> label_blossom(1, :s)

      assert LeastSlack.get_best_blossom_edge(ctx) == {-1, 0}
    end

    test "finds minimum slack across multiple S-blossoms" do
      ctx =
        [{0, 1, 5}, {2, 3, 3}]
        |> Graph.new()
        |> Context.new()
        |> LeastSlack.reset()
        |> label_blossom(0, :s)
        |> label_blossom(1, :s)
        |> label_blossom(2, :s)
        |> label_blossom(3, :s)

      blossom0 = Context.get_vertex_blossom_id(ctx, 0)
      blossom2 = Context.get_vertex_blossom_id(ctx, 2)
      slack0 = Slack.edge_slack_2x(ctx, 0)
      slack1 = Slack.edge_slack_2x(ctx, 1)

      ctx =
        ctx
        |> LeastSlack.add_blossom_edge(blossom0, 0, slack0)
        |> LeastSlack.add_blossom_edge(blossom2, 1, slack1)

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
      ctx =
        [{0, 1, 5}, {1, 2, 5}, {0, 2, 5}, {2, 3, 5}]
        |> Graph.new()
        |> Context.new()
        |> LeastSlack.reset()

      id0 = Context.get_vertex_blossom_id(ctx, 0)
      id1 = Context.get_vertex_blossom_id(ctx, 1)
      id2 = Context.get_vertex_blossom_id(ctx, 2)
      id3 = Context.get_vertex_blossom_id(ctx, 3)

      nt_blossom =
        [id0, id1, id2]
        |> NonTrivial.new([{0, 1}, {1, 2}, {2, 0}], 0)
        |> then(&%{&1 | label: :s})

      ctx =
        ctx
        |> Context.update_blossom(id0, label: :s)
        |> Context.update_blossom(id1, label: :s)
        |> Context.update_blossom(id2, label: :s)
        |> Context.update_blossom(id3, label: :s)
        |> Context.add_blossom(nt_blossom)
        |> Context.update_blossom(id0, parent_id: nt_blossom.id)
        |> Context.update_blossom(id1, parent_id: nt_blossom.id)
        |> Context.update_blossom(id2, parent_id: nt_blossom.id)
        |> Context.set_vertices_blossom([0, 1, 2], nt_blossom.id)
        |> LeastSlack.merge_blossoms(nt_blossom.id)

      blossom = Context.get_blossom(ctx, nt_blossom.id)

      # Edge 3 (2-3) connects to external S-blossom, should be in best_edge_set
      assert blossom.best_edge == 3
      assert 3 in blossom.best_edge_set
    end

    test "filters out internal edges" do
      ctx =
        [{0, 1, 5}, {1, 2, 5}, {0, 2, 5}]
        |> Graph.new()
        |> Context.new()
        |> LeastSlack.reset()

      id0 = Context.get_vertex_blossom_id(ctx, 0)
      id1 = Context.get_vertex_blossom_id(ctx, 1)
      id2 = Context.get_vertex_blossom_id(ctx, 2)

      nt_blossom =
        [id0, id1, id2]
        |> NonTrivial.new([{0, 1}, {1, 2}, {2, 0}], 0)
        |> then(&%{&1 | label: :s})

      ctx =
        ctx
        |> Context.update_blossom(id0, label: :s)
        |> Context.update_blossom(id1, label: :s)
        |> Context.update_blossom(id2, label: :s)
        |> Context.add_blossom(nt_blossom)
        |> Context.update_blossom(id0, parent_id: nt_blossom.id)
        |> Context.update_blossom(id1, parent_id: nt_blossom.id)
        |> Context.update_blossom(id2, parent_id: nt_blossom.id)
        |> Context.set_vertices_blossom([0, 1, 2], nt_blossom.id)
        |> LeastSlack.merge_blossoms(nt_blossom.id)

      blossom = Context.get_blossom(ctx, nt_blossom.id)

      # No external edges, so best_edge should be -1
      assert blossom.best_edge == -1
      assert blossom.best_edge_set == []
    end

    test "filters out edges to non-S blossoms" do
      # Triangle with external unlabeled vertex (id3 stays unlabeled)
      ctx =
        [{0, 1, 5}, {1, 2, 5}, {0, 2, 5}, {2, 3, 5}]
        |> Graph.new()
        |> Context.new()
        |> LeastSlack.reset()

      id0 = Context.get_vertex_blossom_id(ctx, 0)
      id1 = Context.get_vertex_blossom_id(ctx, 1)
      id2 = Context.get_vertex_blossom_id(ctx, 2)

      nt_blossom =
        [id0, id1, id2]
        |> NonTrivial.new([{0, 1}, {1, 2}, {2, 0}], 0)
        |> then(&%{&1 | label: :s})

      ctx =
        ctx
        |> Context.update_blossom(id0, label: :s)
        |> Context.update_blossom(id1, label: :s)
        |> Context.update_blossom(id2, label: :s)
        |> Context.add_blossom(nt_blossom)
        |> Context.update_blossom(id0, parent_id: nt_blossom.id)
        |> Context.update_blossom(id1, parent_id: nt_blossom.id)
        |> Context.update_blossom(id2, parent_id: nt_blossom.id)
        |> Context.set_vertices_blossom([0, 1, 2], nt_blossom.id)
        |> LeastSlack.merge_blossoms(nt_blossom.id)

      blossom = Context.get_blossom(ctx, nt_blossom.id)

      # Edge to unlabeled vertex is filtered out
      assert blossom.best_edge == -1
      assert blossom.best_edge_set == []
    end

    test "ignores T-labeled sub-blossoms" do
      # Triangle where one sub-blossom is labeled T
      ctx =
        [{0, 1, 5}, {1, 2, 5}, {0, 2, 5}, {2, 3, 5}]
        |> Graph.new()
        |> Context.new()
        |> LeastSlack.reset()

      id0 = Context.get_vertex_blossom_id(ctx, 0)
      id1 = Context.get_vertex_blossom_id(ctx, 1)
      id2 = Context.get_vertex_blossom_id(ctx, 2)
      id3 = Context.get_vertex_blossom_id(ctx, 3)

      nt_blossom =
        [id0, id1, id2]
        |> NonTrivial.new([{0, 1}, {1, 2}, {2, 0}], 0)
        |> then(&%{&1 | label: :s})

      # 0 and 1 are S, 2 is T (so its edges won't be scanned)
      ctx =
        ctx
        |> Context.update_blossom(id0, label: :s)
        |> Context.update_blossom(id1, label: :s)
        |> Context.update_blossom(id2, label: :t)
        |> Context.update_blossom(id3, label: :s)
        |> Context.add_blossom(nt_blossom)
        |> Context.update_blossom(id0, parent_id: nt_blossom.id)
        |> Context.update_blossom(id1, parent_id: nt_blossom.id)
        |> Context.update_blossom(id2, parent_id: nt_blossom.id)
        |> Context.set_vertices_blossom([0, 1, 2], nt_blossom.id)
        |> LeastSlack.merge_blossoms(nt_blossom.id)

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
      ctx =
        [
          {0, 1, 5},
          {1, 2, 5},
          {0, 2, 5},
          {3, 4, 5},
          {4, 5, 5},
          {3, 5, 5},
          {2, 3, 5}
        ]
        |> Graph.new()
        |> Context.new()
        |> LeastSlack.reset()

      id0 = Context.get_vertex_blossom_id(ctx, 0)
      id1 = Context.get_vertex_blossom_id(ctx, 1)
      id2 = Context.get_vertex_blossom_id(ctx, 2)
      id3 = Context.get_vertex_blossom_id(ctx, 3)
      id4 = Context.get_vertex_blossom_id(ctx, 4)
      id5 = Context.get_vertex_blossom_id(ctx, 5)

      inner_blossom =
        [id0, id1, id2]
        |> NonTrivial.new([{0, 1}, {1, 2}, {2, 0}], 0)
        |> then(&%{&1 | label: :s, best_edge_set: [6]})

      outer_blossom =
        [inner_blossom.id, id3, id5]
        |> NonTrivial.new([{2, 3}, {3, 5}, {5, 0}], 0)
        |> then(&%{&1 | label: :s})

      ctx =
        ctx
        |> Context.update_blossom(id0, label: :s)
        |> Context.update_blossom(id1, label: :s)
        |> Context.update_blossom(id2, label: :s)
        |> Context.update_blossom(id3, label: :s)
        |> Context.update_blossom(id4, label: :s)
        |> Context.update_blossom(id5, label: :s)
        |> Context.add_blossom(inner_blossom)
        |> Context.update_blossom(id0, parent_id: inner_blossom.id)
        |> Context.update_blossom(id1, parent_id: inner_blossom.id)
        |> Context.update_blossom(id2, parent_id: inner_blossom.id)
        |> Context.set_vertices_blossom([0, 1, 2], inner_blossom.id)
        |> Context.add_blossom(outer_blossom)
        |> Context.update_blossom(inner_blossom.id, parent_id: outer_blossom.id)
        |> Context.update_blossom(id3, parent_id: outer_blossom.id)
        |> Context.update_blossom(id5, parent_id: outer_blossom.id)
        |> Context.set_vertices_blossom([0, 1, 2, 3, 5], outer_blossom.id)
        |> LeastSlack.merge_blossoms(outer_blossom.id)

      # The inner blossom's best_edge_set should have been cleared
      inner = Context.get_blossom(ctx, inner_blossom.id)
      assert inner.best_edge_set == nil
    end

    test "keeps best edge per external S-blossom" do
      # Graph: triangle (0-1-2) with two edges to same external vertex 3
      # Edge 3: 0-3 (weight 10), Edge 4: 2-3 (weight 3)
      # Slack for edge 3 (weight 10): 10 + 10 - 20 = 0
      # Slack for edge 4 (weight 3): 10 + 10 - 6 = 14
      # Edge 3 has LESS slack, so it should be kept
      ctx =
        [{0, 1, 5}, {1, 2, 5}, {0, 2, 5}, {0, 3, 10}, {2, 3, 3}]
        |> Graph.new()
        |> Context.new()
        |> LeastSlack.reset()

      id0 = Context.get_vertex_blossom_id(ctx, 0)
      id1 = Context.get_vertex_blossom_id(ctx, 1)
      id2 = Context.get_vertex_blossom_id(ctx, 2)
      id3 = Context.get_vertex_blossom_id(ctx, 3)

      nt_blossom =
        [id0, id1, id2]
        |> NonTrivial.new([{0, 1}, {1, 2}, {2, 0}], 0)
        |> then(&%{&1 | label: :s})

      ctx =
        ctx
        |> Context.update_blossom(id0, label: :s)
        |> Context.update_blossom(id1, label: :s)
        |> Context.update_blossom(id2, label: :s)
        |> Context.update_blossom(id3, label: :s)
        |> Context.add_blossom(nt_blossom)
        |> Context.update_blossom(id0, parent_id: nt_blossom.id)
        |> Context.update_blossom(id1, parent_id: nt_blossom.id)
        |> Context.update_blossom(id2, parent_id: nt_blossom.id)
        |> Context.set_vertices_blossom([0, 1, 2], nt_blossom.id)
        |> LeastSlack.merge_blossoms(nt_blossom.id)

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
      # Slack for edge 3: 10 + 10 - 20 = 0
      # Slack for edge 4: 10 + 10 - 6 = 14
      # Edge 3 has LESS slack (0), so it's the best_edge
      ctx =
        [{0, 1, 5}, {1, 2, 5}, {0, 2, 5}, {0, 3, 10}, {2, 4, 3}]
        |> Graph.new()
        |> Context.new()
        |> LeastSlack.reset()

      id0 = Context.get_vertex_blossom_id(ctx, 0)
      id1 = Context.get_vertex_blossom_id(ctx, 1)
      id2 = Context.get_vertex_blossom_id(ctx, 2)
      id3 = Context.get_vertex_blossom_id(ctx, 3)
      id4 = Context.get_vertex_blossom_id(ctx, 4)

      nt_blossom =
        [id0, id1, id2]
        |> NonTrivial.new([{0, 1}, {1, 2}, {2, 0}], 0)
        |> then(&%{&1 | label: :s})

      ctx =
        ctx
        |> Context.update_blossom(id0, label: :s)
        |> Context.update_blossom(id1, label: :s)
        |> Context.update_blossom(id2, label: :s)
        |> Context.update_blossom(id3, label: :s)
        |> Context.update_blossom(id4, label: :s)
        |> Context.add_blossom(nt_blossom)
        |> Context.update_blossom(id0, parent_id: nt_blossom.id)
        |> Context.update_blossom(id1, parent_id: nt_blossom.id)
        |> Context.update_blossom(id2, parent_id: nt_blossom.id)
        |> Context.set_vertices_blossom([0, 1, 2], nt_blossom.id)
        |> LeastSlack.merge_blossoms(nt_blossom.id)

      blossom = Context.get_blossom(ctx, nt_blossom.id)

      # Both edges should be in best_edge_set (one to each external blossom)
      assert length(blossom.best_edge_set) == 2
      # Edge 3 (0-3, weight 10) has less slack (0), so it's the best_edge
      assert blossom.best_edge == 3
    end
  end
end
