defmodule Elswisser.Pairings do
  alias Elswisser.Scores.Score
  alias Elswisser.Pairings.Pairing
  alias Elswisser.Pairings.PairWeight
  alias Elswisser.Pairings.Worker

  defguardp is_even(scores) when is_list(scores) and rem(length(scores), 2) == 0

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

  def pair(nil), do: pair([])

  def pair(scores) when is_map(scores) do
    Map.values(scores) |> pair()
  end

  @doc """
  Do automated pairings. Assumes an input of sorted player-augmented Score.
  """
  def pair(scores) when is_even(scores) do
    max_score = max_score(scores)

    scores |> partition() |> unique_possible_pairs(max_score) |> Worker.pooled_call()
  end

  def partition(scores) when is_list(scores) do
    halfway = ceil(length(scores) / 2)

    Enum.with_index(scores, fn score, idx ->
      %Pairing{
        player_id: score.player_id,
        upperhalf: idx < halfway,
        half_idx: if(idx < halfway, do: idx, else: idx - halfway),
        score: score
      }
    end)
  end

  def max_score(scores) when is_list(scores) do
    Enum.reduce(scores, 0, fn score, acc -> max(score.score, acc) end)
  end

  def unique_possible_pairs(pairings) when is_list(pairings) do
    unique_possible_pairs(pairings, 0)
  end

  def unique_possible_pairs(pairings, max_score)
      when is_list(pairings) and is_number(max_score) do
    for p1 <- pairings,
        p2 <- pairings,
        p1.player_id != p2.player_id,
        reduce: %{} do
      acc ->
        if Map.has_key?(acc, {p1.player_id, p2.player_id}) or
             Map.has_key?(acc, {p2.player_id, p1.player_id}) do
          acc
        else
          Map.put(
            acc,
            {p1.player_id, p2.player_id},
            {p1.player_id, p2.player_id, PairWeight.score(p1, p2, max_score)}
          )
        end
    end
    |> Map.values()
  end

  @doc """
  Given a list of tuples of player_ids for the pairings and a map of player_id
  to score, return the list of tuples with {:white_id, :black_id}.
  """
  def assign_colors(pairings, scores) when is_map(scores) do
    Enum.map(pairings, fn {left, right} ->
      left_score = Map.get(scores, left, %Score{})
      right_score = Map.get(scores, right, %Score{})

      cond do
        # left player has had more black games, they should get the next white game
        left_score.nblack > right_score.nblack ->
          {left, right}

        # right player has had more black games, they should get the next white game
        right_score.nblack > left_score.nblack ->
          {right, left}

        # same number of black games, but left player was white most recently
        left_score.lastwhite && !right_score.lastwhite ->
          {right, left}

        true ->
          {left, right}
      end
    end)
  end

  @doc """
  Given an input of scores (sorted first to last placement), pick a player to receive a bye.
  """
  def assign_bye_player(scores) when is_even(scores) do
    {:none, scores}
  end

  def assign_bye_player(scores) when is_list(scores) do
    lowest_scoring_player =
      scores
      |> Enum.filter(fn s -> !Score.had_bye?(s) end)
      |> Enum.at(-1)

    case is_nil(lowest_scoring_player) do
      true ->
        {Enum.at(scores, -1), Enum.take(scores, length(scores - 1))}

      false ->
        {lowest_scoring_player,
         Enum.filter(scores, fn s -> s.player_id != lowest_scoring_player.player_id end)}
    end
  end
end
