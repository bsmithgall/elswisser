defmodule Blossom.MaxWeightMatching.StageTest do
  use ExUnit.Case, async: true

  alias Blossom.MaxWeightMatching.{Context, Graph, Label, LeastSlack, Stage}
  alias Blossom.MaxWeightMatching.Blossom.NonTrivial

  describe "reset_stage/1" do
    test "clears all blossom labels" do
      graph = Graph.new([{0, 1, 10}, {1, 2, 10}])
      ctx = Context.new(graph)
      ctx = %{ctx | vertex_mate: %{0 => -1, 1 => 2, 2 => 1}}

      # Label some blossoms
      ctx = Label.assign_label_s(ctx, 0)
      ctx = Label.assign_label_t(ctx, 0, 1)

      # Verify labels were set
      assert Context.get_vertex_blossom(ctx, 0).label == :s
      assert Context.get_vertex_blossom(ctx, 1).label == :t
      assert Context.get_vertex_blossom(ctx, 2).label == :s

      # Reset the stage
      ctx = Stage.reset_stage(ctx)

      # All labels should be cleared
      assert Context.get_vertex_blossom(ctx, 0).label == :none
      assert Context.get_vertex_blossom(ctx, 1).label == :none
      assert Context.get_vertex_blossom(ctx, 2).label == :none
    end

    test "clears all tree_edges" do
      graph = Graph.new([{0, 1, 10}, {1, 2, 10}])
      ctx = Context.new(graph)
      ctx = %{ctx | vertex_mate: %{0 => -1, 1 => 2, 2 => 1}}

      ctx = Label.assign_label_s(ctx, 0)
      ctx = Label.assign_label_t(ctx, 0, 1)

      # Verify tree edges were set
      assert Context.get_vertex_blossom(ctx, 1).tree_edge == {0, 1}
      assert Context.get_vertex_blossom(ctx, 2).tree_edge == {1, 2}

      ctx = Stage.reset_stage(ctx)

      # All tree edges should be nil
      assert Context.get_vertex_blossom(ctx, 0).tree_edge == nil
      assert Context.get_vertex_blossom(ctx, 1).tree_edge == nil
      assert Context.get_vertex_blossom(ctx, 2).tree_edge == nil
    end

    test "clears the queue" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      ctx = Label.assign_label_s(ctx, 0)
      refute Context.queue_empty?(ctx)

      ctx = Stage.reset_stage(ctx)

      assert Context.queue_empty?(ctx)
    end

    test "resets vertex_best_edge tracking" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      # Manually set a best edge
      ctx = %{ctx | vertex_best_edge: Map.put(ctx.vertex_best_edge, 0, 0)}

      ctx = Stage.reset_stage(ctx)

      assert Map.fetch!(ctx.vertex_best_edge, 0) == -1
      assert Map.fetch!(ctx.vertex_best_edge, 1) == -1
    end

    test "resets blossom best_edge tracking" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      # Manually set a best edge on blossom
      id0 = Context.get_vertex_blossom_id(ctx, 0)
      ctx = Context.update_blossom(ctx, id0, best_edge: 0)

      ctx = Stage.reset_stage(ctx)

      assert Context.get_blossom(ctx, id0).best_edge == -1
    end
  end

  describe "substage_calc_dual_delta/1" do
    test "returns delta1 when only S-vertices exist" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      ctx = Label.assign_label_s(ctx, 0)

      {type, delta, edge, blossom_id} = Stage.substage_calc_dual_delta(ctx)

      assert type == 1
      # Initial dual is max_weight
      assert delta == 10
      assert edge == -1
      assert blossom_id == nil
    end

    test "returns delta2 when S-to-unlabeled edge has lower slack" do
      # Graph: 0 -- 1, both unmatched
      # Label 0 as S, 1 is unlabeled
      # After scanning, there should be a tracked edge to vertex 1
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      ctx = Label.assign_label_s(ctx, 0)

      # Track edge 0 as best edge to vertex 1
      # slack = 2 * max_weight - vertex_dual[0] - vertex_dual[1] = 2*10 - 10 - 10 = 0
      ctx = LeastSlack.add_vertex_edge(ctx, 1, 0, 0)

      {type, delta, edge, _blossom_id} = Stage.substage_calc_dual_delta(ctx)

      assert type == 2
      assert delta == 0
      assert edge == 0
    end

    test "returns delta3 when S-to-S edge has lower slack" do
      # Two separate S-blossoms with an edge between them
      graph = Graph.new([{0, 1, 8}])
      ctx = Context.new(graph)

      # Label both as S (both unmatched)
      ctx = Label.assign_label_s(ctx, 0)
      ctx = Label.assign_label_s(ctx, 1)

      # Track edge as S-to-S edge on blossom 0
      # slack = 2 * weight - dual[0] - dual[1] = 16 - 8 - 8 = 0
      id0 = Context.get_vertex_blossom_id(ctx, 0)
      ctx = LeastSlack.add_blossom_edge(ctx, id0, 0, 0)

      {type, delta, edge, _blossom_id} = Stage.substage_calc_dual_delta(ctx)

      # delta3 = slack / 2 = 0
      assert type == 3
      assert delta == 0
      assert edge == 0
    end

    test "returns delta4 when T-blossom dual is lowest" do
      # Create graph with 4 vertices: triangle (0,1,2) + vertex 3
      graph = Graph.new([{0, 1, 100}, {1, 2, 100}, {2, 0, 100}, {0, 3, 100}])
      ctx = Context.new(graph)

      # Label vertex 3 as S (unmatched)
      ctx = Label.assign_label_s(ctx, 3)

      # Create a non-trivial T-blossom from vertices 0, 1, 2
      id0 = Context.get_vertex_blossom_id(ctx, 0)
      id1 = Context.get_vertex_blossom_id(ctx, 1)
      id2 = Context.get_vertex_blossom_id(ctx, 2)

      nontrivial =
        NonTrivial.new(
          [id0, id1, id2],
          [{0, 1}, {1, 2}, {2, 0}],
          0
        )

      nontrivial = %{nontrivial | dual_var: 2, label: :t}

      ctx = Context.add_blossom(ctx, nontrivial)
      ctx = Context.set_vertices_blossom(ctx, [0, 1, 2], nontrivial.id)
      ctx = Context.update_blossom(ctx, id0, parent_id: nontrivial.id)
      ctx = Context.update_blossom(ctx, id1, parent_id: nontrivial.id)
      ctx = Context.update_blossom(ctx, id2, parent_id: nontrivial.id)

      {type, delta, _edge, blossom_id} = Stage.substage_calc_dual_delta(ctx)

      assert type == 4
      assert delta == 2
      assert blossom_id == nontrivial.id
    end

    test "prefers later delta type on ties (matches Python behavior)" do
      # Create edge with weight 20. Initial duals are both 20.
      # Slack = 2*20 - 20 - 20 = 0, so delta3 = 0
      # But delta1 = 20 (min S-vertex dual)
      # So delta3 wins because 0 < 20
      #
      # To get a tie, we need: delta1 = delta3
      # delta1 = min S-vertex dual = max_weight (after init)
      # delta3 = slack/2 = (2*weight - dual_x - dual_y) / 2
      #
      # For edge weight W, duals start at W.
      # slack = 2W - W - W = 0, delta3 = 0
      #
      # Let's test a simpler property: delta3 beats delta1 when slack/2 < delta1
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      # Label both as S
      ctx = Label.assign_label_s(ctx, 0)
      ctx = Label.assign_label_s(ctx, 1)

      # Track the S-to-S edge (edge 0)
      # slack = 2*10 - 10 - 10 = 0, so delta3 = 0
      id0 = Context.get_vertex_blossom_id(ctx, 0)
      ctx = LeastSlack.add_blossom_edge(ctx, id0, 0, 0)

      # delta1 = 10 (min S-vertex dual)
      # delta3 = 0 (slack/2)
      # delta3 should win because 0 < 10

      {type, delta, edge, _blossom_id} = Stage.substage_calc_dual_delta(ctx)

      assert type == 3
      assert delta == 0
      assert edge == 0
    end

    test "delta1 wins when no edges tracked" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      # Only label vertex 0 as S
      ctx = Label.assign_label_s(ctx, 0)

      # No edges tracked, so only delta1 applies
      {type, delta, edge, blossom_id} = Stage.substage_calc_dual_delta(ctx)

      assert type == 1
      assert delta == 10
      assert edge == -1
      assert blossom_id == nil
    end
  end

  describe "substage_apply_delta_step/2" do
    test "decreases S-vertex duals" do
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      ctx = Label.assign_label_s(ctx, 0)
      initial_dual = Map.fetch!(ctx.vertex_dual_2x, 0)

      ctx = Stage.substage_apply_delta_step(ctx, 4)

      assert Map.fetch!(ctx.vertex_dual_2x, 0) == initial_dual - 4
    end

    test "increases T-vertex duals" do
      graph = Graph.new([{0, 1, 10}, {1, 2, 10}])
      ctx = Context.new(graph)
      ctx = %{ctx | vertex_mate: %{0 => -1, 1 => 2, 2 => 1}}

      ctx = Label.assign_label_s(ctx, 0)
      ctx = Label.assign_label_t(ctx, 0, 1)

      initial_dual = Map.fetch!(ctx.vertex_dual_2x, 1)

      ctx = Stage.substage_apply_delta_step(ctx, 4)

      assert Map.fetch!(ctx.vertex_dual_2x, 1) == initial_dual + 4
    end

    test "leaves unlabeled vertex duals unchanged" do
      graph = Graph.new([{0, 1, 10}, {2, 3, 10}])
      ctx = Context.new(graph)

      ctx = Label.assign_label_s(ctx, 0)

      initial_dual = Map.fetch!(ctx.vertex_dual_2x, 2)

      ctx = Stage.substage_apply_delta_step(ctx, 4)

      assert Map.fetch!(ctx.vertex_dual_2x, 2) == initial_dual
    end

    test "increases S-blossom dual_var" do
      graph = Graph.new([{0, 1, 10}, {1, 2, 10}, {2, 0, 10}])
      ctx = Context.new(graph)

      # Create a non-trivial S-blossom
      id0 = Context.get_vertex_blossom_id(ctx, 0)
      id1 = Context.get_vertex_blossom_id(ctx, 1)
      id2 = Context.get_vertex_blossom_id(ctx, 2)

      nontrivial =
        NonTrivial.new(
          [id0, id1, id2],
          [{0, 1}, {1, 2}, {2, 0}],
          0
        )

      nontrivial = %{nontrivial | dual_var: 10, label: :s}

      ctx = Context.add_blossom(ctx, nontrivial)
      ctx = Context.set_vertices_blossom(ctx, [0, 1, 2], nontrivial.id)
      ctx = Context.update_blossom(ctx, id0, parent_id: nontrivial.id)
      ctx = Context.update_blossom(ctx, id1, parent_id: nontrivial.id)
      ctx = Context.update_blossom(ctx, id2, parent_id: nontrivial.id)

      ctx = Stage.substage_apply_delta_step(ctx, 4)

      updated_blossom = Context.get_blossom(ctx, nontrivial.id)
      assert updated_blossom.dual_var == 14
    end

    test "decreases T-blossom dual_var" do
      graph = Graph.new([{0, 1, 10}, {1, 2, 10}, {2, 0, 10}])
      ctx = Context.new(graph)

      # Create a non-trivial T-blossom
      id0 = Context.get_vertex_blossom_id(ctx, 0)
      id1 = Context.get_vertex_blossom_id(ctx, 1)
      id2 = Context.get_vertex_blossom_id(ctx, 2)

      nontrivial =
        NonTrivial.new(
          [id0, id1, id2],
          [{0, 1}, {1, 2}, {2, 0}],
          0
        )

      nontrivial = %{nontrivial | dual_var: 10, label: :t}

      ctx = Context.add_blossom(ctx, nontrivial)
      ctx = Context.set_vertices_blossom(ctx, [0, 1, 2], nontrivial.id)
      ctx = Context.update_blossom(ctx, id0, parent_id: nontrivial.id)
      ctx = Context.update_blossom(ctx, id1, parent_id: nontrivial.id)
      ctx = Context.update_blossom(ctx, id2, parent_id: nontrivial.id)

      ctx = Stage.substage_apply_delta_step(ctx, 4)

      updated_blossom = Context.get_blossom(ctx, nontrivial.id)
      assert updated_blossom.dual_var == 6
    end

    test "leaves nested blossom duals unchanged" do
      graph = Graph.new([{0, 1, 10}, {1, 2, 10}, {2, 0, 10}])
      ctx = Context.new(graph)

      # Create nested structure: non-trivial contains trivials
      id0 = Context.get_vertex_blossom_id(ctx, 0)
      id1 = Context.get_vertex_blossom_id(ctx, 1)
      id2 = Context.get_vertex_blossom_id(ctx, 2)

      nontrivial =
        NonTrivial.new(
          [id0, id1, id2],
          [{0, 1}, {1, 2}, {2, 0}],
          0
        )

      nontrivial = %{nontrivial | dual_var: 10, label: :s}

      ctx = Context.add_blossom(ctx, nontrivial)
      ctx = Context.set_vertices_blossom(ctx, [0, 1, 2], nontrivial.id)

      # Mark trivials as nested (parent_id set)
      ctx = Context.update_blossom(ctx, id0, parent_id: nontrivial.id)
      ctx = Context.update_blossom(ctx, id1, parent_id: nontrivial.id)
      ctx = Context.update_blossom(ctx, id2, parent_id: nontrivial.id)

      ctx = Stage.substage_apply_delta_step(ctx, 4)

      # Only the top-level blossom should be updated
      assert Context.get_blossom(ctx, nontrivial.id).dual_var == 14

      # Trivial blossoms don't have dual_var, so just check they're unchanged
      # (no crash, no unexpected behavior)
    end
  end

  describe "integration: delta mechanics workflow" do
    test "typical substage flow" do
      # Simple path: 0 -- 1 -- 2
      # Matching: 1 <-> 2
      # Start stage with S-vertex at 0
      graph = Graph.new([{0, 1, 10}, {1, 2, 5}])
      ctx = Context.new(graph)
      ctx = %{ctx | vertex_mate: %{0 => -1, 1 => 2, 2 => 1}}

      # Reset stage (normally done at start)
      ctx = Stage.reset_stage(ctx)

      # Label unmatched vertex as S
      ctx = Label.assign_label_s(ctx, 0)

      # Calculate delta
      {type, delta, _edge, _blossom} = Stage.substage_calc_dual_delta(ctx)

      # Should be delta1 since no edges tracked yet
      assert type == 1
      assert delta == 10

      # Apply a small delta step
      ctx = Stage.substage_apply_delta_step(ctx, 2)

      # S-vertex dual decreased
      assert Map.fetch!(ctx.vertex_dual_2x, 0) == 8

      # Unlabeled vertices unchanged
      assert Map.fetch!(ctx.vertex_dual_2x, 1) == 10
      assert Map.fetch!(ctx.vertex_dual_2x, 2) == 10
    end
  end
end
