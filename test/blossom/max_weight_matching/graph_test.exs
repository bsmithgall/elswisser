defmodule Blossom.MaxWeightMatching.GraphTest do
  use ExUnit.Case, async: true

  alias Blossom.MaxWeightMatching.Graph

  describe "new/1" do
    test "empty graph has num_vertex 0" do
      graph = Graph.new([])
      assert graph.num_vertex == 0
      assert graph.edges == []
      assert graph.adjacent_edges == %{}
      assert graph.integer_weights == true
    end

    test "single edge {0, 1, 5} has num_vertex 2" do
      graph = Graph.new([{0, 1, 5}])
      assert graph.num_vertex == 2
    end

    test "edge {0, 5, 10} has num_vertex 6 (fills gaps)" do
      graph = Graph.new([{0, 5, 10}])
      assert graph.num_vertex == 6
    end

    test "computes num_vertex from maximum vertex index" do
      graph = Graph.new([{3, 7, 10}, {1, 2, 5}])
      assert graph.num_vertex == 8
    end

    test "adjacent_edges maps vertices to edge indices (order-agnostic)" do
      graph = Graph.new([{0, 1, 10}, {1, 2, 5}])

      # Use MapSet for order-agnostic comparison since edge indices
      # may be stored in any order within the adjacency lists
      assert MapSet.new(graph.adjacent_edges[0]) == MapSet.new([0])
      assert MapSet.new(graph.adjacent_edges[1]) == MapSet.new([0, 1])
      assert MapSet.new(graph.adjacent_edges[2]) == MapSet.new([1])
    end

    test "adjacent_edges includes all vertices even if not connected" do
      graph = Graph.new([{0, 5, 10}])

      # All vertices 0-5 should have entries
      assert Map.has_key?(graph.adjacent_edges, 0)
      assert Map.has_key?(graph.adjacent_edges, 1)
      assert Map.has_key?(graph.adjacent_edges, 2)
      assert Map.has_key?(graph.adjacent_edges, 3)
      assert Map.has_key?(graph.adjacent_edges, 4)
      assert Map.has_key?(graph.adjacent_edges, 5)

      # Intermediate vertices have no edges
      assert graph.adjacent_edges[1] == []
      assert graph.adjacent_edges[2] == []
      assert graph.adjacent_edges[3] == []
      assert graph.adjacent_edges[4] == []
    end

    test "integer_weights is true when all weights are integers" do
      graph = Graph.new([{0, 1, 10}, {1, 2, 5}, {2, 3, 100}])
      assert graph.integer_weights == true
    end

    test "integer_weights is false when any weight is float" do
      graph = Graph.new([{0, 1, 10}, {1, 2, 5.5}])
      assert graph.integer_weights == false
    end

    test "integer_weights is false when all weights are floats" do
      graph = Graph.new([{0, 1, 10.0}, {1, 2, 5.5}])
      assert graph.integer_weights == false
    end

    test "stores edges in original order" do
      edges = [{0, 1, 10}, {2, 3, 5}, {1, 2, 8}]
      graph = Graph.new(edges)
      assert graph.edges == edges
    end

    test "handles graph with single vertex pair" do
      graph = Graph.new([{0, 1, 42}])
      assert graph.num_vertex == 2
      assert graph.edges == [{0, 1, 42}]
      assert MapSet.new(graph.adjacent_edges[0]) == MapSet.new([0])
      assert MapSet.new(graph.adjacent_edges[1]) == MapSet.new([0])
    end

    test "handles graph with many edges from same vertex" do
      # Star graph: vertex 0 connected to vertices 1, 2, 3
      edges = [{0, 1, 10}, {0, 2, 20}, {0, 3, 30}]
      graph = Graph.new(edges)

      assert graph.num_vertex == 4
      # Vertex 0 should have all three edge indices (order-agnostic)
      assert MapSet.new(graph.adjacent_edges[0]) == MapSet.new([0, 1, 2])
    end
  end
end
