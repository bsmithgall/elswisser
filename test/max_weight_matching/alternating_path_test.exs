defmodule MaxWeightMatching.AlternatingPathTest do
  use ExUnit.Case, async: true

  alias MaxWeightMatching.{Context, Graph, Label, AlternatingPath}

  describe "trace_alternating_paths/3 - augmenting path (different trees)" do
    test "finds augmenting path between two unmatched S-vertices" do
      # Simple edge: 0 -- 1, both unmatched
      # Both are roots of separate alternating trees
      ctx =
        [{0, 1, 10}]
        |> Graph.new()
        |> Context.new()
        |> Label.assign_label_s(0)
        |> Label.assign_label_s(1)

      {path, ctx} = AlternatingPath.trace_alternating_paths(ctx, 0, 1)

      # Path should be a single edge connecting 0 and 1 (direction may vary)
      assert length(path.edges) == 1
      [{a, b}] = path.edges
      assert Enum.sort([a, b]) == [0, 1]

      # Markers should be cleared
      assert Context.get_vertex_blossom(ctx, 0).marker == false
      assert Context.get_vertex_blossom(ctx, 1).marker == false
    end

    test "finds augmenting path through alternating tree" do
      # Path graph: 0 -- 1 -- 2 -- 3 -- 4 -- 5
      # Matching: 1<->2, 3<->4
      # Tree from 0: 0(S) -> 1(T) -> 2(S)
      # Tree from 5: 5(S) -> 4(T) -> 3(S)
      # Edge 2 -- 3 connects them
      ctx =
        [{0, 1, 10}, {1, 2, 10}, {2, 3, 10}, {3, 4, 10}, {4, 5, 10}]
        |> Graph.new()
        |> Context.new()
        |> then(&%{&1 | vertex_mate: %{0 => -1, 1 => 2, 2 => 1, 3 => 4, 4 => 3, 5 => -1}})
        |> Label.assign_label_s(0)
        |> Label.assign_label_t(0, 1)
        |> Label.assign_label_s(5)
        |> Label.assign_label_t(5, 4)

      # Find augmenting path from vertex 2 (S) to vertex 3 (S)
      {path, ctx} = AlternatingPath.trace_alternating_paths(ctx, 2, 3)

      # Path should have 5 edges (odd length)
      assert length(path.edges) == 5
      assert rem(length(path.edges), 2) == 1

      # Path should connect the two unmatched vertices (0 and 5)
      [{first_x, _} | _] = path.edges
      {_, last_y} = List.last(path.edges)
      assert Enum.sort([first_x, last_y]) == [0, 5]

      # All markers should be cleared
      for v <- 0..5 do
        assert Context.get_vertex_blossom(ctx, v).marker == false
      end
    end
  end

  describe "trace_alternating_paths/3 - blossom cycle (same tree)" do
    test "finds cycle when both vertices in same tree" do
      # Graph: 0 -- 1 -- 2 -- 3 -- 4 -- 0 (pentagon)
      # Matching: 1<->2, 3<->4
      # Tree: 0(S) -> 1(T) -> 2(S) -> 3(T) -> 4(S)
      # Edge 0 -- 4 connects two S-vertices in same tree
      # Note: With trivial blossoms only, cycle detection requires non-trivial blossoms.
      ctx =
        [{0, 1, 10}, {1, 2, 10}, {2, 3, 10}, {3, 4, 10}, {4, 0, 10}]
        |> Graph.new()
        |> Context.new()
        |> then(&%{&1 | vertex_mate: %{0 => -1, 1 => 2, 2 => 1, 3 => 4, 4 => 3}})
        |> Label.assign_label_s(0)
        |> Label.assign_label_t(0, 1)
        |> Label.assign_label_t(2, 3)

      {path, ctx} = AlternatingPath.trace_alternating_paths(ctx, 0, 4)

      # Path should have odd length
      assert rem(length(path.edges), 2) == 1

      # Markers cleared
      for v <- 0..4 do
        assert Context.get_vertex_blossom(ctx, v).marker == false
      end
    end
  end

  describe "trace_alternating_paths/3 - marker cleanup" do
    test "clears all markers even when path found early" do
      ctx =
        [{0, 1, 10}]
        |> Graph.new()
        |> Context.new()
        |> Label.assign_label_s(0)
        |> Label.assign_label_s(1)

      # Verify markers are initially false
      assert Context.get_vertex_blossom(ctx, 0).marker == false
      assert Context.get_vertex_blossom(ctx, 1).marker == false

      {_path, ctx} = AlternatingPath.trace_alternating_paths(ctx, 0, 1)

      # Markers should be cleared after tracing
      assert Context.get_vertex_blossom(ctx, 0).marker == false
      assert Context.get_vertex_blossom(ctx, 1).marker == false
    end

    test "clears markers on all visited blossoms" do
      # Longer path to ensure multiple blossoms are visited
      ctx =
        [{0, 1, 10}, {1, 2, 10}, {2, 3, 10}]
        |> Graph.new()
        |> Context.new()
        |> then(&%{&1 | vertex_mate: %{0 => -1, 1 => 2, 2 => 1, 3 => -1}})
        |> Label.assign_label_s(0)
        |> Label.assign_label_t(0, 1)
        |> Label.assign_label_s(3)

      {_path, ctx} = AlternatingPath.trace_alternating_paths(ctx, 2, 3)

      # All markers should be cleared
      for v <- 0..3 do
        assert Context.get_vertex_blossom(ctx, v).marker == false
      end
    end
  end

  describe "trace_alternating_paths/3 - path properties" do
    test "path has odd number of edges" do
      # Any S-to-S path must have odd length
      ctx =
        [{0, 1, 10}]
        |> Graph.new()
        |> Context.new()
        |> Label.assign_label_s(0)
        |> Label.assign_label_s(1)

      {path, _ctx} = AlternatingPath.trace_alternating_paths(ctx, 0, 1)

      assert rem(length(path.edges), 2) == 1
    end

    test "path edges are properly ordered" do
      # Path should be continuous: edge[i][1] == edge[i+1][0]
      ctx =
        [{0, 1, 10}, {1, 2, 10}, {2, 3, 10}]
        |> Graph.new()
        |> Context.new()
        |> then(&%{&1 | vertex_mate: %{0 => -1, 1 => 2, 2 => 1, 3 => -1}})
        |> Label.assign_label_s(0)
        |> Label.assign_label_t(0, 1)
        |> Label.assign_label_s(3)

      {path, _ctx} = AlternatingPath.trace_alternating_paths(ctx, 2, 3)

      # Check edge continuity
      path.edges
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.each(fn [{_, y}, {x, _}] ->
        assert y == x, "Edge discontinuity: #{y} != #{x}"
      end)
    end
  end
end
