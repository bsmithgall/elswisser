defmodule MaxWeightMatching.Blossom.Trivial do
  @moduledoc """
  A trivial blossom containing a single vertex.

  ## Fields

  - `id` - Unique identifier created by `make_ref()`
  - `base_vertex` - The single vertex contained in this blossom
  - `parent_id` - ID of parent blossom if this is a sub-blossom, nil if top-level
  - `label` - Current label: `:none`, `:s` (outer), or `:t` (inner)
  - `tree_edge` - Edge `{x, y}` attaching this to alternating tree, nil if root
  - `best_edge` - Index of least-slack edge to S-blossom, -1 if none found
  - `marker` - Temporary flag used during path tracing
  """

  @type t :: %__MODULE__{
          id: reference(),
          base_vertex: non_neg_integer(),
          parent_id: reference() | nil,
          label: :none | :s | :t,
          tree_edge: {non_neg_integer(), non_neg_integer()} | nil,
          best_edge: integer(),
          marker: boolean()
        }

  defstruct [
    :id,
    :base_vertex,
    parent_id: nil,
    label: :none,
    tree_edge: nil,
    best_edge: -1,
    marker: false
  ]

  @doc """
  Creates a new trivial blossom for the given vertex.

  ## Examples

      iex> blossom = MaxWeightMatching.Blossom.Trivial.new(0)
      iex> blossom.base_vertex
      0
      iex> is_reference(blossom.id)
      true
  """
  @spec new(non_neg_integer()) :: t()
  def new(vertex) when is_integer(vertex) and vertex >= 0 do
    %__MODULE__{
      id: make_ref(),
      base_vertex: vertex
    }
  end
end
