defmodule Blossom.MaxWeightMatching.SlackTest do
  use ExUnit.Case, async: true

  alias Blossom.MaxWeightMatching.Context
  alias Blossom.MaxWeightMatching.Graph
  alias Blossom.MaxWeightMatching.Slack

  describe "edge_slack_2x/2" do
    test "calculates slack for simple edge" do
      # Edge {0, 1, 5} with max weight 5
      # Initial duals are set to max weight (5)
      # Slack = dual[0] + dual[1] - 2*weight = 5 + 5 - 10 = 0
      graph = Graph.new([{0, 1, 5}])
      ctx = Context.new(graph)

      assert Slack.edge_slack_2x(ctx, 0) == 0
    end

    test "calculates positive slack when duals exceed weight" do
      # Edge {0, 1, 3} with another edge {0, 2, 10}
      # Max weight = 10, so duals are all 10
      # Slack for edge 0 = 10 + 10 - 2*3 = 14
      graph = Graph.new([{0, 1, 3}, {0, 2, 10}])
      ctx = Context.new(graph)

      assert Slack.edge_slack_2x(ctx, 0) == 14
    end

    test "calculates zero slack for tight edge" do
      # When duals exactly match: dual[x] + dual[y] = 2*w
      graph = Graph.new([{0, 1, 10}])
      ctx = Context.new(graph)

      # Max weight = 10, so duals are 10 each
      # Slack = 10 + 10 - 20 = 0
      assert Slack.edge_slack_2x(ctx, 0) == 0
    end

    test "works with multiple edges" do
      # Triangle graph
      graph = Graph.new([{0, 1, 5}, {1, 2, 3}, {0, 2, 4}])
      ctx = Context.new(graph)

      # Max weight = 5, all duals = 5
      # Edge 0: 5 + 5 - 10 = 0
      # Edge 1: 5 + 5 - 6 = 4
      # Edge 2: 5 + 5 - 8 = 2
      assert Slack.edge_slack_2x(ctx, 0) == 0
      assert Slack.edge_slack_2x(ctx, 1) == 4
      assert Slack.edge_slack_2x(ctx, 2) == 2
    end

    test "works with float weights" do
      graph = Graph.new([{0, 1, 5.5}])
      ctx = Context.new(graph)

      # Max weight = 5.5, duals = 5.5
      # Slack = 5.5 + 5.5 - 11.0 = 0.0
      assert Slack.edge_slack_2x(ctx, 0) == 0.0
    end

    test "raises when vertices are in same blossom" do
      graph = Graph.new([{0, 1, 5}])
      ctx = Context.new(graph)

      # Manually put both vertices in the same blossom
      blossom_id = Context.get_vertex_blossom_id(ctx, 0)
      ctx = Context.set_vertex_blossom(ctx, 1, blossom_id)

      assert_raise ArgumentError, ~r/same top-level blossom/, fn ->
        Slack.edge_slack_2x(ctx, 0)
      end
    end

    test "works after dual variable updates" do
      graph = Graph.new([{0, 1, 5}])
      ctx = Context.new(graph)

      # Manually update dual variables
      ctx = %{ctx | vertex_dual_2x: %{0 => 8, 1 => 6}}

      # Slack = 8 + 6 - 10 = 4
      assert Slack.edge_slack_2x(ctx, 0) == 4
    end
  end
end
