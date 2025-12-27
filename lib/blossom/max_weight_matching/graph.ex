defmodule Blossom.MaxWeightMatching.Graph do
  @moduledoc """
  Representation of the input graph for the maximum weight matching algorithm.

  The graph is immutable and stores:
  - The edge list with weights
  - Number of vertices (derived from maximum vertex index + 1)
  - Adjacency list mapping vertices to incident edge indices
  - Whether all weights are integers (enables optimizations)
  """

  @type t :: %__MODULE__{
          edges: [{non_neg_integer(), non_neg_integer(), number()}],
          num_vertex: non_neg_integer(),
          adjacent_edges: %{non_neg_integer() => [non_neg_integer()]},
          integer_weights: boolean()
        }

  defstruct [:edges, :num_vertex, :adjacent_edges, :integer_weights]

  @doc """
  Creates a new Graph from a list of edges.

  Each edge is a 3-tuple `{x, y, w}` where:
  - `x` and `y` are vertex indices (non-negative integers)
  - `w` is the edge weight (integer or float)

  Vertices are indexed by consecutive non-negative integers starting from 0.
  The number of vertices is derived as `max(vertex_index) + 1`.

  ## Examples

      iex> Graph.new([{0, 1, 10}, {1, 2, 5}])
      %Graph{
        edges: [{0, 1, 10}, {1, 2, 5}],
        num_vertex: 3,
        adjacent_edges: %{0 => [0], 1 => [1, 0], 2 => [1]},
        integer_weights: true
      }

      iex> Graph.new([])
      %Graph{edges: [], num_vertex: 0, adjacent_edges: %{}, integer_weights: true}
  """
  @spec new([{non_neg_integer(), non_neg_integer(), number()}]) :: t()
  def new(edges) when is_list(edges) do
    num_vertex = compute_num_vertex(edges)
    adjacent_edges = build_adjacency_list(edges, num_vertex)
    integer_weights = Enum.all?(edges, fn {_x, _y, w} -> is_integer(w) end)

    %__MODULE__{
      edges: edges,
      num_vertex: num_vertex,
      adjacent_edges: adjacent_edges,
      integer_weights: integer_weights
    }
  end

  # Computes the number of vertices as max(vertex_index) + 1
  defp compute_num_vertex([]), do: 0

  defp compute_num_vertex(edges) do
    edges
    |> Enum.flat_map(fn {x, y, _w} -> [x, y] end)
    |> Enum.max()
    |> Kernel.+(1)
  end

  # Builds an adjacency list mapping each vertex to its incident edge indices.
  # Note: Edge indices are prepended for O(1) insertion, so they appear in reverse
  # order compared to the input edge list. This does not affect algorithm correctness
  # since the matching algorithm doesn't depend on edge ordering in adjacency lists.
  defp build_adjacency_list(_edges, 0), do: %{}

  defp build_adjacency_list(edges, num_vertex) do
    # Start with empty list for each vertex
    initial = Map.new(0..(num_vertex - 1), fn v -> {v, []} end)

    edges
    |> Enum.with_index()
    |> Enum.reduce(initial, fn {{x, y, _w}, edge_index}, acc ->
      acc
      |> Map.update!(x, fn list -> [edge_index | list] end)
      |> Map.update!(y, fn list -> [edge_index | list] end)
    end)
  end
end
