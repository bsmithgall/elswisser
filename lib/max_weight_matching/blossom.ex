defmodule MaxWeightMatching.Blossom do
  @moduledoc """
  Blossom data structures for the maximum weight matching algorithm.

  A blossom is an odd-length alternating cycle over sub-blossoms. An alternating
  path consists of alternating matched and unmatched edges. An alternating cycle
  is an alternating path that starts and ends in the same sub-blossom.

  A single vertex by itself is a "trivial blossom". A non-trivial blossom contains
  multiple sub-blossoms (at least 3, since all blossoms have odd length).

  Blossoms are recursive structures: a non-trivial blossom contains sub-blossoms,
  which may themselves contain sub-blossoms.

  Each blossom contains exactly one vertex that is not matched to another vertex
  in the same blossom. This is the "base vertex" of the blossom.

  ## Design Notes

  We use `make_ref()` for unique blossom IDs to enable identity comparison in
  Elixir's immutable world. Parent/child relationships are stored as IDs rather
  than direct references to avoid circular structures.
  """

  alias MaxWeightMatching.Blossom.{Trivial, NonTrivial}

  @type label :: :none | :s | :t
  @type blossom_id :: reference()
  @type blossom :: Trivial.t() | NonTrivial.t()

  @doc """
  Returns a list of all vertex indices contained in the blossom.

  For trivial blossoms, returns a single-element list.
  For non-trivial blossoms, recursively collects vertices from all sub-blossoms.

  Uses an explicit stack to avoid deep recursion with nested blossoms.

  ## Parameters

  - `blossom_id` - The ID of the blossom to get vertices from
  - `blossoms` - Map of blossom IDs to blossom structs

  ## Examples

      iex> trivial = MaxWeightMatching.Blossom.Trivial.new(5)
      iex> blossoms = %{trivial.id => trivial}
      iex> MaxWeightMatching.Blossom.vertices(trivial.id, blossoms)
      [5]
  """
  @spec vertices(blossom_id(), %{blossom_id() => blossom()}) :: [non_neg_integer()]
  def vertices(blossom_id, blossoms) do
    do_vertices([blossom_id], [], blossoms)
  end

  defp do_vertices([], acc, _blossoms), do: acc

  defp do_vertices([id | rest], acc, blossoms) do
    case Map.fetch!(blossoms, id) do
      %Trivial{base_vertex: v} ->
        do_vertices(rest, [v | acc], blossoms)

      %NonTrivial{subblossom_ids: sub_ids} ->
        do_vertices(sub_ids ++ rest, acc, blossoms)
    end
  end
end
