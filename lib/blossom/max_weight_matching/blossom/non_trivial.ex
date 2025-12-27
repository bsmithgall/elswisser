defmodule Blossom.MaxWeightMatching.Blossom.NonTrivial do
  @moduledoc """
  A non-trivial blossom containing multiple sub-blossoms.

  Non-trivial blossoms represent odd-length alternating cycles discovered by
  the algorithm. They contain at least 3 sub-blossoms (since all blossoms have
  odd length).

  Unlike trivial blossoms, each non-trivial blossom has an associated dual
  variable in the linear programming problem.

  ## Fields

  - `id` - Unique identifier created by `make_ref()`
  - `base_vertex` - The base vertex (contained but not matched within blossom)
  - `subblossom_ids` - List of sub-blossom IDs in cycle order
  - `edges` - List of edges `{x, y}` linking consecutive sub-blossoms
  - `parent_id` - ID of parent blossom if nested, nil if top-level
  - `label` - Current label: `:none`, `:s` (outer), or `:t` (inner)
  - `tree_edge` - Edge attaching this to alternating tree, nil if root
  - `best_edge` - Index of least-slack edge to S-blossom, -1 if none
  - `marker` - Temporary flag used during path tracing
  - `dual_var` - Dual variable value for LPP (always >= 0)
  - `best_edge_set` - List of least-slack edges to other S-blossoms
  """

  @type t :: %__MODULE__{
          id: reference(),
          base_vertex: non_neg_integer(),
          subblossom_ids: [reference()],
          edges: [{non_neg_integer(), non_neg_integer()}],
          parent_id: reference() | nil,
          label: :none | :s | :t,
          tree_edge: {non_neg_integer(), non_neg_integer()} | nil,
          best_edge: integer(),
          marker: boolean(),
          dual_var: number(),
          best_edge_set: [non_neg_integer()] | nil
        }

  defstruct [
    :id,
    :base_vertex,
    :subblossom_ids,
    :edges,
    parent_id: nil,
    label: :none,
    tree_edge: nil,
    best_edge: -1,
    marker: false,
    dual_var: 0,
    best_edge_set: nil
  ]

  @doc """
  Creates a new non-trivial blossom from sub-blossoms and connecting edges.

  The sub-blossoms must form an odd-length cycle (at least 3 sub-blossoms).
  The first sub-blossom contains the base vertex of the new blossom.

  ## Parameters

  - `subblossom_ids` - List of sub-blossom IDs in cycle order
  - `edges` - List of edges linking consecutive sub-blossoms
  - `base_vertex` - The base vertex (from first sub-blossom)

  ## Examples

      iex> blossom = Blossom.MaxWeightMatching.Blossom.NonTrivial.new([ref1, ref2, ref3], [{0,1}, {1,2}, {2,0}], 0)
      iex> length(blossom.subblossom_ids)
      3
  """
  @spec new([reference()], [{non_neg_integer(), non_neg_integer()}], non_neg_integer()) :: t()
  def new(subblossom_ids, edges, base_vertex)
      when is_list(subblossom_ids) and is_list(edges) and is_integer(base_vertex) do
    n = length(subblossom_ids)

    cond do
      length(edges) != n ->
        raise ArgumentError, "edges length must equal subblossoms length"

      n < 3 ->
        raise ArgumentError, "non-trivial blossom must have at least 3 sub-blossoms"

      rem(n, 2) != 1 ->
        raise ArgumentError, "non-trivial blossom must have odd number of sub-blossoms"

      true ->
        %__MODULE__{
          id: make_ref(),
          base_vertex: base_vertex,
          subblossom_ids: subblossom_ids,
          edges: edges
        }
    end
  end
end
