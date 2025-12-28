defmodule TestSupport.GraphGenerator do
  @moduledoc """
  Generates random graphs for testing the maximum weight matching algorithm.

  Provides utilities to create various types of test graphs including:
  - Random graphs with configurable density
  - Complete graphs
  - Bipartite graphs
  - Odd cycles
  """

  @doc """
  Generates a random graph with the given number of vertices.

  ## Parameters

  - `num_vertices` - Number of vertices in the graph (vertices are 0..n-1)
  - `density` - Probability of including each possible edge (0.0 to 1.0)
  - `weight_range` - Range of edge weights as `{min, max}`

  ## Examples

      iex> GraphGenerator.random_graph(5, 0.5, {1, 10})
      [{0, 2, 7}, {1, 3, 4}, ...]  # varies by random seed
  """
  @spec random_graph(non_neg_integer(), float(), {number(), number()}) :: list()
  def random_graph(num_vertices, density, {min_weight, max_weight} = _weight_range)
      when num_vertices >= 0 and density >= 0.0 and density <= 1.0 do
    for i <- 0..(num_vertices - 2),
        j <- (i + 1)..(num_vertices - 1),
        :rand.uniform() < density do
      weight = random_weight(min_weight, max_weight)
      {i, j, weight}
    end
  end

  @doc """
  Generates a complete graph Kn with random weights.

  ## Parameters

  - `n` - Number of vertices
  - `weight_range` - Range of edge weights as `{min, max}`

  ## Examples

      iex> GraphGenerator.complete_graph(3, {1, 10})
      [{0, 1, 5}, {0, 2, 8}, {1, 2, 3}]  # weights vary
  """
  @spec complete_graph(non_neg_integer(), {number(), number()}) :: list()
  def complete_graph(n, {min_weight, max_weight} = _weight_range) when n >= 0 do
    for i <- 0..(n - 2),
        j <- (i + 1)..(n - 1) do
      weight = random_weight(min_weight, max_weight)
      {i, j, weight}
    end
  end

  @doc """
  Generates a complete graph Kn with uniform weight.

  ## Parameters

  - `n` - Number of vertices
  - `weight` - Weight for all edges

  ## Examples

      iex> GraphGenerator.complete_graph_uniform(3, 1)
      [{0, 1, 1}, {0, 2, 1}, {1, 2, 1}]
  """
  @spec complete_graph_uniform(non_neg_integer(), number()) :: list()
  def complete_graph_uniform(n, weight) when n >= 0 do
    for i <- 0..(n - 2),
        j <- (i + 1)..(n - 1) do
      {i, j, weight}
    end
  end

  @doc """
  Generates a random bipartite graph.

  Creates a bipartite graph with left vertices 0..(left_size-1) and
  right vertices left_size..(left_size+right_size-1).

  ## Parameters

  - `left_size` - Number of vertices in left partition
  - `right_size` - Number of vertices in right partition
  - `density` - Probability of including each possible edge (0.0 to 1.0)
  - `weight_range` - Range of edge weights as `{min, max}`

  ## Examples

      iex> GraphGenerator.bipartite_graph(2, 2, 1.0, {1, 10})
      [{0, 2, 5}, {0, 3, 8}, {1, 2, 3}, {1, 3, 7}]  # weights vary
  """
  @spec bipartite_graph(non_neg_integer(), non_neg_integer(), float(), {number(), number()}) ::
          list()
  def bipartite_graph(left_size, right_size, density, {min_weight, max_weight} = _weight_range)
      when left_size >= 0 and right_size >= 0 and density >= 0.0 and density <= 1.0 do
    for i <- 0..(left_size - 1),
        j <- left_size..(left_size + right_size - 1),
        :rand.uniform() < density do
      weight = random_weight(min_weight, max_weight)
      {i, j, weight}
    end
  end

  @doc """
  Generates a complete bipartite graph K(m,n).

  ## Parameters

  - `left_size` - Number of vertices in left partition
  - `right_size` - Number of vertices in right partition
  - `weight_range` - Range of edge weights as `{min, max}`
  """
  @spec complete_bipartite_graph(non_neg_integer(), non_neg_integer(), {number(), number()}) ::
          list()
  def complete_bipartite_graph(left_size, right_size, {min_weight, max_weight} = _weight_range)
      when left_size >= 0 and right_size >= 0 do
    for i <- 0..(left_size - 1),
        j <- left_size..(left_size + right_size - 1) do
      weight = random_weight(min_weight, max_weight)
      {i, j, weight}
    end
  end

  @doc """
  Generates an odd cycle with the given length.

  ## Parameters

  - `length` - Number of vertices in the cycle (must be odd and >= 3)
  - `weight` - Weight for all edges

  ## Examples

      iex> GraphGenerator.odd_cycle(5, 1)
      [{0, 1, 1}, {1, 2, 1}, {2, 3, 1}, {3, 4, 1}, {4, 0, 1}]
  """
  @spec odd_cycle(pos_integer(), number()) :: list()
  def odd_cycle(length, weight) when length >= 3 and rem(length, 2) == 1 do
    for i <- 0..(length - 1) do
      j = rem(i + 1, length)
      {i, j, weight}
    end
  end

  @doc """
  Generates an even cycle with the given length.

  ## Parameters

  - `length` - Number of vertices in the cycle (must be even and >= 4)
  - `weight` - Weight for all edges
  """
  @spec even_cycle(pos_integer(), number()) :: list()
  def even_cycle(length, weight) when length >= 4 and rem(length, 2) == 0 do
    for i <- 0..(length - 1) do
      j = rem(i + 1, length)
      {i, j, weight}
    end
  end

  @doc """
  Generates a path graph with the given number of vertices.

  ## Parameters

  - `num_vertices` - Number of vertices in the path
  - `weight` - Weight for all edges
  """
  @spec path(pos_integer(), number()) :: list()
  def path(num_vertices, weight) when num_vertices >= 2 do
    for i <- 0..(num_vertices - 2) do
      {i, i + 1, weight}
    end
  end

  @doc """
  Generates a star graph with one central vertex connected to n outer vertices.

  ## Parameters

  - `num_outer` - Number of outer vertices (total vertices = num_outer + 1)
  - `weight_range` - Range of edge weights as `{min, max}`
  """
  @spec star(pos_integer(), {number(), number()}) :: list()
  def star(num_outer, {min_weight, max_weight} = _weight_range) when num_outer >= 1 do
    for i <- 1..num_outer do
      weight = random_weight(min_weight, max_weight)
      {0, i, weight}
    end
  end

  @doc """
  Generates a random connected graph.

  First creates a spanning tree to ensure connectivity, then adds random edges
  based on density.

  ## Parameters

  - `num_vertices` - Number of vertices
  - `density` - Probability of including each additional edge (0.0 to 1.0)
  - `weight_range` - Range of edge weights as `{min, max}`
  """
  @spec connected_graph(non_neg_integer(), float(), {number(), number()}) :: list()
  def connected_graph(num_vertices, density, {min_weight, max_weight} = weight_range)
      when num_vertices >= 2 and density >= 0.0 and density <= 1.0 do
    # Create a random spanning tree first
    tree_edges = random_spanning_tree(num_vertices, weight_range)

    # Create a set of tree edges for fast lookup
    tree_edge_set =
      MapSet.new(tree_edges, fn {i, j, _w} ->
        if i < j, do: {i, j}, else: {j, i}
      end)

    # Add random additional edges
    additional_edges =
      for i <- 0..(num_vertices - 2),
          j <- (i + 1)..(num_vertices - 1),
          not MapSet.member?(tree_edge_set, {i, j}),
          :rand.uniform() < density do
        weight = random_weight(min_weight, max_weight)
        {i, j, weight}
      end

    tree_edges ++ additional_edges
  end

  # Helper to create a random spanning tree using random parent selection
  defp random_spanning_tree(num_vertices, {min_weight, max_weight}) do
    for i <- 1..(num_vertices - 1) do
      parent = :rand.uniform(i) - 1
      weight = random_weight(min_weight, max_weight)
      {min(i, parent), max(i, parent), weight}
    end
  end

  # Helper to generate a random weight in range
  defp random_weight(min_weight, max_weight)
       when is_integer(min_weight) and is_integer(max_weight) do
    :rand.uniform(max_weight - min_weight + 1) + min_weight - 1
  end

  defp random_weight(min_weight, max_weight) do
    :rand.uniform() * (max_weight - min_weight) + min_weight
  end
end
