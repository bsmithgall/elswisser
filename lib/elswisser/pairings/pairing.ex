defmodule Elswisser.Pairings.Pairing do
  alias Elswisser.Pairings.PairWeight

  @moduledoc """
  Pair players according (as best as possible) to the USCF [pairing rules].

  Specifically, do the following:
  1. Split players into an upper and lower half based first on their scores and
     then on their ratings.
  2. For each pair of players, give the pairing a "score", based on the
     following factors (descending order of importance):
      1. Have the players played yet?
      2. Do the players have an equal score?
      3. If the players have an equal score, where are they in the relevant score
         group (as defined by rating)?
      4. Are the players ready to be matched due to have opposite colors?
  3. Convert each one of those pairing scores into a weighted undirected graph,
     and use the [blossom algorithm] to pick the maximum matching graph.

  [pairing rules]:
      https://new.uschess.org/sites/default/files/media/documents/us-chess-rule-book-online-only-edition-chapters-1-2-10-11-9-1-20.pdf
  [blossom algorithm]: https://en.wikipedia.org/wiki/Blossom_algorithm
  """

  defstruct player_id: -1,
            score: %Elswisser.Scores{},
            upperhalf: false,
            half_idx: -1

  def pair(nil), do: pair([])

  @doc """
  Do automated pairings. Assumes an input of sorted player-augmented Elswisser.Scores.
  """
  def pair(scores) when is_list(scores) do
    max_score = max_score(scores)

    scores |> partition() |> cartesian_product(max_score) |> to_graph()
  end

  def partition(scores) when is_list(scores) do
    halfway = ceil(length(scores) / 2)

    Enum.with_index(scores, fn score, idx ->
      %Elswisser.Pairings.Pairing{
        player_id: score.id,
        upperhalf: idx < halfway,
        half_idx: if(idx < halfway, do: idx, else: idx - halfway),
        score: score
      }
    end)
  end

  def max_score(scores) when is_list(scores) do
    Enum.reduce(scores, 0, fn score, acc -> max(score.score, acc) end)
  end

  def cartesian_product(pairings) when is_list(pairings) do
    cartesian_product(pairings, 0)
  end

  def cartesian_product(pairings, max_score) when is_list(pairings) and is_number(max_score) do
    for p1 <- pairings,
        p2 <- pairings,
        p1.player_id != p2.player_id,
        do: {p1.player_id, p2.player_id, weight: PairWeight.score(p1, p2, max_score)}
  end

  def to_graph(scored_pairings) when is_list(scored_pairings) do
    Graph.new(type: :undirected) |> Graph.add_edges(scored_pairings)
  end
end
