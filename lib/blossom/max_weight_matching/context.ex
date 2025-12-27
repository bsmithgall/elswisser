defmodule Blossom.MaxWeightMatching.Context do
  @moduledoc """
  Holds all state used by the maximum weight matching algorithm.

  The context contains a partial solution of the matching problem and several
  auxiliary data structures. Since Elixir is immutable, all operations that
  modify state return a new Context struct.

  ## Fields

  - `graph` - Reference to the input graph (immutable)
  - `vertex_mate` - Map from vertex to its matched partner (-1 if unmatched)
  - `blossoms` - Map from blossom ID to blossom struct (Trivial or NonTrivial)
  - `vertex_top_blossom_id` - Map from vertex to its top-level blossom ID
  - `vertex_dual_2x` - Map from vertex to 2x its dual variable
  - `vertex_best_edge` - Map from vertex to index of least-slack edge to S-vertex
  - `queue` - Queue of S-vertices to be scanned

  ## Design Notes

  Blossoms are stored in a map keyed by `make_ref()` IDs. This enables O(1)
  lookup and immutable updates. The `vertex_top_blossom_id` map provides the
  mapping from vertices to their current top-level blossom.

  Dual variables are stored as 2x their actual values to maintain integer
  arithmetic when all edge weights are integers.
  """

  alias Blossom.MaxWeightMatching.Graph
  alias Blossom.MaxWeightMatching.Blossom.Trivial
  alias Blossom.MaxWeightMatching.Blossom.NonTrivial
  alias Blossom.MaxWeightMatching.Blossom

  @type t :: %__MODULE__{
          graph: Graph.t(),
          vertex_mate: %{non_neg_integer() => integer()},
          blossoms: %{reference() => Trivial.t() | NonTrivial.t()},
          vertex_top_blossom_id: %{non_neg_integer() => reference()},
          vertex_dual_2x: %{non_neg_integer() => number()},
          vertex_best_edge: %{non_neg_integer() => integer()},
          queue: :queue.queue(non_neg_integer())
        }

  defstruct [
    :graph,
    :vertex_mate,
    :blossoms,
    :vertex_top_blossom_id,
    :vertex_dual_2x,
    :vertex_best_edge,
    :queue
  ]

  @doc """
  Creates a new matching context from a graph.

  Initializes:
  - A trivial blossom for each vertex
  - All vertices as unmatched (mate = -1)
  - Vertex duals to max edge weight (stored as 2x)
  - Best edges to -1 (none found)
  - Empty queue

  ## Examples

      iex> graph = Graph.new([{0, 1, 10}])
      iex> ctx = Context.new(graph)
      iex> ctx.vertex_mate[0]
      -1
      iex> ctx.vertex_dual_2x[0]
      10
  """
  @spec new(Graph.t()) :: t()
  def new(%Graph{} = graph) do
    num_vertex = graph.num_vertex

    if num_vertex == 0 do
      %__MODULE__{
        graph: graph,
        vertex_mate: %{},
        blossoms: %{},
        vertex_top_blossom_id: %{},
        vertex_dual_2x: %{},
        vertex_best_edge: %{},
        queue: :queue.new()
      }
    else
      # Create trivial blossoms for each vertex
      trivial_blossoms =
        for v <- 0..(num_vertex - 1), into: %{} do
          blossom = Trivial.new(v)
          {blossom.id, blossom}
        end

      # Map vertices to their trivial blossom IDs
      vertex_to_blossom_id =
        for {id, blossom} <- trivial_blossoms, into: %{} do
          {blossom.base_vertex, id}
        end

      # Get max weight for initial dual values
      max_weight =
        graph.edges
        |> Enum.map(fn {_x, _y, w} -> w end)
        |> Enum.max()

      %__MODULE__{
        graph: graph,
        vertex_mate: Map.new(0..(num_vertex - 1), fn v -> {v, -1} end),
        blossoms: trivial_blossoms,
        vertex_top_blossom_id: vertex_to_blossom_id,
        vertex_dual_2x: Map.new(0..(num_vertex - 1), fn v -> {v, max_weight} end),
        vertex_best_edge: Map.new(0..(num_vertex - 1), fn v -> {v, -1} end),
        queue: :queue.new()
      }
    end
  end

  @doc """
  Gets a blossom by its ID.

  Raises if the blossom ID is not found.

  ## Examples

      iex> blossom = Context.get_blossom(ctx, blossom_id)
      %Trivial{...}
  """
  @spec get_blossom(t(), reference()) :: Trivial.t() | NonTrivial.t()
  def get_blossom(%__MODULE__{blossoms: blossoms}, id) do
    Map.fetch!(blossoms, id)
  end

  @doc """
  Gets the top-level blossom containing a vertex.

  ## Examples

      iex> blossom = Context.get_vertex_blossom(ctx, 0)
      %Trivial{base_vertex: 0, ...}
  """
  @spec get_vertex_blossom(t(), non_neg_integer()) :: Trivial.t() | NonTrivial.t()
  def get_vertex_blossom(%__MODULE__{} = ctx, vertex) do
    id = Map.fetch!(ctx.vertex_top_blossom_id, vertex)
    get_blossom(ctx, id)
  end

  @doc """
  Gets the ID of the top-level blossom containing a vertex.

  ## Examples

      iex> id = Context.get_vertex_blossom_id(ctx, 0)
      #Reference<...>
  """
  @spec get_vertex_blossom_id(t(), non_neg_integer()) :: reference()
  def get_vertex_blossom_id(%__MODULE__{vertex_top_blossom_id: mapping}, vertex) do
    Map.fetch!(mapping, vertex)
  end

  @doc """
  Updates a blossom in the context.

  Returns a new context with the updated blossom.

  ## Parameters

  - `ctx` - The current context
  - `id` - The blossom ID to update
  - `updates` - A map or keyword list of field updates

  ## Examples

      iex> ctx = Context.update_blossom(ctx, blossom_id, label: :s)
      iex> Context.get_blossom(ctx, blossom_id).label
      :s
  """
  @spec update_blossom(t(), reference(), map() | keyword()) :: t()
  def update_blossom(%__MODULE__{blossoms: blossoms} = ctx, id, updates) do
    updated_blossoms = Map.update!(blossoms, id, &struct(&1, updates))
    %{ctx | blossoms: updated_blossoms}
  end

  @doc """
  Checks if two vertices belong to the same top-level blossom.

  ## Examples

      iex> Context.same_blossom?(ctx, 0, 1)
      false
  """
  @spec same_blossom?(t(), non_neg_integer(), non_neg_integer()) :: boolean()
  def same_blossom?(%__MODULE__{vertex_top_blossom_id: mapping}, vertex_x, vertex_y) do
    Map.fetch!(mapping, vertex_x) == Map.fetch!(mapping, vertex_y)
  end

  @doc """
  Adds a blossom to the context.

  Returns a new context with the blossom added to the blossoms map.

  ## Examples

      iex> ctx = Context.add_blossom(ctx, blossom)
  """
  @spec add_blossom(t(), Trivial.t() | NonTrivial.t()) :: t()
  def add_blossom(%__MODULE__{blossoms: blossoms} = ctx, blossom) do
    %{ctx | blossoms: Map.put(blossoms, blossom.id, blossom)}
  end

  @doc """
  Removes a blossom from the context.

  Returns a new context with the blossom removed from the blossoms map.

  ## Examples

      iex> ctx = Context.remove_blossom(ctx, blossom_id)
  """
  @spec remove_blossom(t(), reference()) :: t()
  def remove_blossom(%__MODULE__{blossoms: blossoms} = ctx, id) do
    %{ctx | blossoms: Map.delete(blossoms, id)}
  end

  @doc """
  Updates the vertex to top-level blossom mapping for a single vertex.

  ## Examples

      iex> ctx = Context.set_vertex_blossom(ctx, 0, new_blossom_id)
  """
  @spec set_vertex_blossom(t(), non_neg_integer(), reference()) :: t()
  def set_vertex_blossom(%__MODULE__{vertex_top_blossom_id: mapping} = ctx, vertex, blossom_id) do
    %{ctx | vertex_top_blossom_id: Map.put(mapping, vertex, blossom_id)}
  end

  @doc """
  Updates the vertex to top-level blossom mapping for multiple vertices.

  ## Examples

      iex> ctx = Context.set_vertices_blossom(ctx, [0, 1, 2], new_blossom_id)
  """
  @spec set_vertices_blossom(t(), [non_neg_integer()], reference()) :: t()
  def set_vertices_blossom(%__MODULE__{} = ctx, vertices, blossom_id) do
    Enum.reduce(vertices, ctx, fn v, acc ->
      set_vertex_blossom(acc, v, blossom_id)
    end)
  end

  @doc """
  Gets all vertices contained in a blossom.

  Delegates to `Blossom.vertices/2`.

  ## Examples

      iex> Context.blossom_vertices(ctx, blossom_id)
      [0, 1, 2]
  """
  @spec blossom_vertices(t(), reference()) :: [non_neg_integer()]
  def blossom_vertices(%__MODULE__{blossoms: blossoms}, blossom_id) do
    Blossom.vertices(blossom_id, blossoms)
  end

  @doc """
  Adds vertices to the scanning queue.

  ## Examples

      iex> ctx = Context.enqueue(ctx, [0, 1, 2])
  """
  @spec enqueue(t(), [non_neg_integer()]) :: t()
  def enqueue(%__MODULE__{queue: queue} = ctx, vertices) when is_list(vertices) do
    new_queue = Enum.reduce(vertices, queue, fn v, q -> :queue.in(v, q) end)
    %{ctx | queue: new_queue}
  end

  @doc """
  Removes and returns the next vertex from the queue.

  Returns `{vertex, new_context}` or `:empty` if queue is empty.

  ## Examples

      iex> {vertex, ctx} = Context.dequeue(ctx)
      {0, %Context{...}}

      iex> Context.dequeue(empty_ctx)
      :empty
  """
  @spec dequeue(t()) :: {non_neg_integer(), t()} | :empty
  def dequeue(%__MODULE__{queue: queue} = ctx) do
    case :queue.out(queue) do
      {{:value, vertex}, new_queue} ->
        {vertex, %{ctx | queue: new_queue}}

      {:empty, _queue} ->
        :empty
    end
  end

  @doc """
  Checks if the queue is empty.

  ## Examples

      iex> Context.queue_empty?(ctx)
      true
  """
  @spec queue_empty?(t()) :: boolean()
  def queue_empty?(%__MODULE__{queue: queue}) do
    :queue.is_empty(queue)
  end

  @doc """
  Clears the queue.

  ## Examples

      iex> ctx = Context.clear_queue(ctx)
  """
  @spec clear_queue(t()) :: t()
  def clear_queue(%__MODULE__{} = ctx) do
    %{ctx | queue: :queue.new()}
  end
end
