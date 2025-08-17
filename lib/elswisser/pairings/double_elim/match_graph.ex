defmodule Elswisser.Pairings.DoubleElim.MatchGraph do
  alias __MODULE__

  @moduledoc """
  Generate a full double-elimination bracket. A bracket is represented as a
  graph, where each match (node) has two possible edges: a "winner" edge
  that links the match to the match where the winner goes, and a "loser" edge
  which links the match to where the loser goes.

  The generation algorithm is as follows:

  1. Make all winner's bracket nodes. The total number of nodes
     should be (2 ^ log₂(n)) - 1 where n is the number of players.
  2. Create the two championship rounds. Note that there need to be
     two because of a "grand final reset" possibility.
  3. Make winner's bracket winners edges. This works by noticing that
     each round of the winner's brakcet proceeds as
     2^(n-1), 2^(n-2), ..., 2^1, 2^0 matches. So we partition based on
     decreasing powers of two and then link forwards partition-by-partition.
  4. Make all loser's bracket nodes. Each part of the loser's bracket
     has two "halves." The loser's bracket should start out with
     (2 ^ log₂(n)) - 2 matches.
  5. Link the winner edge of the loser bracket, e.g. advancing
     through the loser bracket. The loser's bracket progression can be
     understood as proceeding 2^(n-2), 2^(n-2), ..., 2^0, 2^0 matches.
     This is because there are two separate halves to each loser's round:
     a "merge" half where players drop from the winner's bracket, and
     "reduction" half. These each have the same number of matches. The
     first round is a special case as it is sort of a "self-merge."
     Following this, each "merge" half takes players from prior loser rounds
     and then winner rounds.
  6. Link the loser edge of tahe winner bracket. In order to prevent
     players from matching up too closely to each other, we will
     want to rotate through different linkage patterns (forward,
     reverse, rotated, reverse rotated).

  Once we have the graph built, the rest becomes a matter of assigning players.
  """

  defstruct id: -1,
            round: -1,
            type: :unknown,
            w: nil,
            l: nil

  @type t :: %MatchGraph{
          id: number(),
          round: number(),
          type: :w | :lm | :lr | :c | :unknown,
          w: number() | nil,
          l: number() | nil
        }

  @spec generate(number()) :: list(MatchGraph.t())
  def generate(size) do
    winner_rounds = winners_half(size) |> link_winners()
    losers = losers_half(size) |> link_losers(length(winner_rounds))
    championships = make_championships(size, length(winner_rounds) + length(losers))

    winners = pair_down_winners(winner_rounds, losers)

    (winners ++ losers ++ championships) |> List.flatten() |> Enum.sort_by(& &1.id)
  end

  @spec winners_half(number()) :: MatchGraph.t()
  def winners_half(size) do
    count = winner_count(size)

    List.duplicate(nil, count)
    |> Enum.with_index()
    |> Enum.map(fn {_, idx} ->
      if idx == count - 1 do
        %MatchGraph{id: idx, type: :w, w: count + loser_count(size)}
      else
        %MatchGraph{id: idx, type: :w}
      end
    end)
  end

  @spec link_winners(list(MatchGraph.t())) :: list(MatchGraph.t())
  def link_winners(matches) do
    partition = partition_winners(matches)

    partition
    |> Enum.with_index()
    |> Enum.map(fn {match_set, idr} ->
      if idr >= length(partition) - 1 do
        match_set |> Enum.map(&struct(&1, %{round: idr + 1}))
      else
        Enum.with_index(match_set)
        |> Enum.map(fn {m, idx} ->
          w = partition |> Enum.at(idr + 1) |> Enum.at(floor(idx / 2))
          struct(m, %{w: w.id, round: idr + 1})
        end)
      end
    end)
  end

  @doc """
  Chunk into pieces by decreasing powers of two.
  """
  @spec partition_winners(list(MatchGraph.t())) :: list(list(MatchGraph.t()))
  def partition_winners(matches) do
    matches
    |> Enum.chunk_while(
      {[], matches, length(matches)},
      fn _, {acc, left, size} ->
        take_amt = ceil(size / 2)

        if take_amt == 1 do
          {:halt, acc ++ left}
        else
          {take, left} = Enum.split(left, take_amt)
          {:cont, take, {[], left, take_amt}}
        end
      end,
      # there will always be one left over
      fn acc -> {:cont, acc, []} end
    )
  end

  @spec make_championships(number(), number()) :: list(MatchGraph.t())
  def make_championships(size, start_round) do
    next = winner_count(size) + loser_count(size) - 1

    [
      %MatchGraph{id: next + 1, type: :c, w: next + 2, l: next + 2, round: start_round + 1},
      %MatchGraph{id: next + 2, type: :c, round: start_round + 2}
    ]
  end

  @spec losers_half(number()) :: list(MatchGraph.t())
  def losers_half(size) do
    count = loser_count(size)
    w_count = winner_count(size)

    List.duplicate(nil, count)
    |> Enum.with_index(winner_count(size))
    |> Enum.map(fn {_, idx} ->
      if idx == count + w_count - 1 do
        %MatchGraph{id: idx, w: count + w_count}
      else
        %MatchGraph{id: idx}
      end
    end)
  end

  @spec link_losers(list(MatchGraph.t()), number()) :: list(MatchGraph.t())
  def link_losers(matches, start_round) do
    partition = partition_losers(matches)

    partition
    |> Enum.with_index()
    |> Enum.map(fn {match_set, idr} ->
      cond do
        idr >= length(partition) - 1 ->
          match_set |> Enum.map(&struct(&1, %{round: idr + 1 + start_round}))

        # "merge" pairing: next round will accept candidates from winner bracket
        rem(idr, 2) == 0 ->
          Enum.with_index(match_set)
          |> Enum.map(fn {m, idx} ->
            w = partition |> Enum.at(idr + 1) |> Enum.at(idx)
            struct(m, %{w: w.id, round: idr + 1 + start_round})
          end)

        # "reduction" pairing: works same as winner's bracket
        rem(idr, 2) != 0 ->
          Enum.with_index(match_set)
          |> Enum.map(fn {m, idx} ->
            w = partition |> Enum.at(idr + 1) |> Enum.at(floor(idx / 2))
            struct(m, %{w: w.id, round: idr + 1 + start_round})
          end)
      end
    end)
  end

  @spec partition_losers(list(MatchGraph.t())) :: list(list(MatchGraph.t()))
  def partition_losers(matches) do
    start_size = ceil(Math.log(length(matches), 2)) - 2

    matches
    |> Enum.chunk_while(
      {[], matches, start_size, :first},
      fn _, {acc, left, pow2, half} ->
        take_amt = ceil(Math.pow(2, pow2))
        {partition, left} = Enum.split(left, take_amt)

        cond do
          pow2 < 0 ->
            {:halt, acc}

          half == :first ->
            {:cont, Enum.map(partition, &struct(&1, %{type: :lm})), {[], left, pow2, :merge}}

          half == :reduction ->
            {:cont, Enum.map(partition, &struct(&1, %{type: :lr})), {[], left, pow2, :merge}}

          half == :merge ->
            {:cont, Enum.map(partition, &struct(&1, %{type: :lm})),
             {[], left, pow2 - 1, :reduction}}
        end
      end,
      fn [] -> {:cont, []} end
    )
  end

  @spec pair_down_winners(list(MatchGraph.t()), list(MatchGraph.t())) :: list(MatchGraph.t())
  def pair_down_winners(winners, losers) do
    merges = losers |> Enum.filter(&(hd(&1).type == :lm))

    # first round is a special case where two players drop down
    [{w, l} | rest] = winners |> Enum.zip(merges)

    first_round =
      w
      |> Enum.chunk_every(2)
      |> Enum.zip(l)
      |> Enum.reduce([], fn {from, to}, acc ->
        [Enum.map(from, &struct(&1, %{l: to.id})) | acc]
      end)
      |> Enum.reverse()
      |> List.flatten()

    # rest of rounds drop down two at a time
    rest =
      rest
      |> Enum.reduce({[], 2}, fn {from, to}, {acc, p} ->
        {[
           from
           |> Enum.zip(next_pattern(length(from), p))
           |> Enum.map(fn {match, idx} -> struct(match, %{l: Enum.at(to, idx).id}) end)
           | acc
         ], p + 1}
      end)
      |> elem(0)

    first_round ++ rest
  end

  # visible for testing

  @spec next_pattern(number(), number()) :: list(number())
  def next_pattern(num, p) when rem(p, 4) == 0 do
    l = floor((num - 1) / 2)..0//-1 |> Enum.map(& &1)
    r = (num - 1)..ceil((num - 1) / 2)//-1 |> Enum.map(& &1)
    l ++ r
  end

  def next_pattern(num, p) when rem(p, 3) == 0 do
    l = ceil((num - 1) / 2)..(num - 1) |> Enum.map(& &1)
    r = 0..floor((num - 1) / 2) |> Enum.map(& &1)
    l ++ r
  end

  def next_pattern(num, p) when rem(p, 2) == 0 do
    (num - 1)..0//-1 |> Enum.to_list()
  end

  def next_pattern(num, _) do
    0..(num - 1) |> Enum.to_list()
  end

  def next_pow2(size), do: Math.pow(2, ceil(Math.log(size, 2)))

  defp winner_count(size), do: next_pow2(size) - 1
  defp loser_count(size), do: next_pow2(size) - 2
end
