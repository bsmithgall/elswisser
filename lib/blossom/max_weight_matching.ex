defmodule Blossom.MaxWeightMatching do
  @moduledoc """
  Algorithm for finding a maximum weight matching in general graphs.

  Implements Edmonds' Blossom Algorithm (1965) which handles odd cycles
  by temporarily contracting them into "blossoms" and expanding them
  after finding augmenting paths.

  ## Algorithm Overview

  Given an undirected graph G = (V, E) where each edge has a weight, a
  **matching** is a subset of edges such that no two edges share a vertex.
  A **maximum weighted matching** is a matching where the sum of edge weights
  is maximized.

  ## Complexity

  - Time: O(n³) where n = number of vertices
  - Space: O(n + m) where m = number of edges

  ## Usage

      edges = [{0, 1, 10}, {1, 2, 5}, {0, 2, 8}]
      Blossom.MaxWeightMatching.maximum_weight_matching(edges)
      #=> [{0, 1}]  # Returns the matching with maximum total weight

  ## Reference

  Based on the Python implementation by Joris van Rantwijk (2023),
  available at https://github.com/jorisvr/maximum-weight-matching

  MIT License - Copyright (c) 2023 Joris van Rantwijk
  """

  alias Blossom.MaxWeightMatching.{Context, Graph, Stage, Validation}

  @type vertex :: non_neg_integer()
  @type weight :: number()
  @type edge :: {vertex(), vertex(), weight()}
  @type matched_pair :: {vertex(), vertex()}

  @doc """
  Computes a maximum-weighted matching in the general undirected weighted graph.

  ## Parameters

  - `edges` - List of edges, each specified as a tuple `{x, y, w}` where
    `x` and `y` are vertex indices and `w` is the edge weight.

  ## Constraints

  - Vertices are indexed by consecutive non-negative integers (0 to n-1)
  - At most one edge between any pair of vertices
  - No self-edges (vertex cannot connect to itself)
  - Edge weights may be integers or floating point numbers
  - Edges with negative weight are ignored

  ## Returns

  List of pairs of matched vertex indices. Each pair `{x, y}` indicates
  that vertex `x` is matched to vertex `y`.

  ## Raises

  - `ArgumentError` if the input does not satisfy the constraints

  ## Examples

      iex> Blossom.MaxWeightMatching.maximum_weight_matching([])
      []

      iex> Blossom.MaxWeightMatching.maximum_weight_matching([{0, 1, 10}])
      [{0, 1}]

      iex> Blossom.MaxWeightMatching.maximum_weight_matching([{0, 1, 5}, {1, 2, 3}])
      [{0, 1}]
  """
  @spec maximum_weight_matching([edge()]) :: [matched_pair()]
  def maximum_weight_matching(edges) do
    with :ok <- Validation.check_input_types(edges),
         :ok <- Validation.check_input_graph(edges) do
      edges
      |> Validation.remove_negative_weight_edges()
      |> do_matching()
    else
      {:error, reason} -> raise ArgumentError, reason
    end
  end

  defp do_matching([]), do: []

  defp do_matching(edges) do
    graph = Graph.new(edges)
    ctx = Context.new(graph)
    ctx = run_stages(ctx)
    extract_matching(edges, ctx)
  end

  defp run_stages(ctx) do
    case Stage.run_stage(ctx) do
      {true, ctx} -> run_stages(ctx)
      {false, ctx} -> ctx
    end
  end

  defp extract_matching(edges, ctx) do
    edges
    |> Enum.filter(fn {x, y, _w} -> Map.fetch!(ctx.vertex_mate, x) == y end)
    |> Enum.map(fn {x, y, _w} -> {x, y} end)
  end
end
