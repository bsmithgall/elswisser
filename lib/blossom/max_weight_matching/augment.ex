defmodule Blossom.MaxWeightMatching.Augment do
  @moduledoc """
  Matching augmentation for the blossom algorithm.

  Augments the current matching along an augmenting path by flipping
  matched and unmatched edges.
  """

  alias Blossom.MaxWeightMatching.Context
  alias Blossom.MaxWeightMatching.AlternatingPath

  @doc """
  Augment the matching through the specified augmenting path.

  The augmenting path must start and end in an unmatched vertex (or a
  blossom with unmatched base). After augmenting, those vertices will
  be matched, and all matched edges on the path become unmatched while
  unmatched edges become matched.

  Time: O(n)

  ## Parameters

  - `ctx` - The current matching context
  - `path` - An augmenting path from `trace_alternating_paths`

  ## Returns

  A new context with the matching augmented along the path.

  ## Note

  This is a simplified version that does not handle augmentation through
  non-trivial blossoms. That functionality is added in Phase 9.
  """
  @spec augment_matching(Context.t(), AlternatingPath.t()) :: Context.t()
  def augment_matching(%Context{} = ctx, %AlternatingPath{edges: edges}) do
    # Walk through the edges that were unmatched before augmenting
    # (edges at even indices: 0, 2, 4, ...)
    edges
    |> Enum.take_every(2)
    |> Enum.reduce(ctx, fn {x, y}, acc ->
      # Update vertex_mate for both endpoints
      vertex_mate =
        acc.vertex_mate
        |> Map.put(x, y)
        |> Map.put(y, x)

      %{acc | vertex_mate: vertex_mate}
    end)
  end
end
