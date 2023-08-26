defmodule Elswisser.Scores do
  alias Elswisser.Scores.Score

  def calculate(nil), do: calculate([])

  def calculate(games) when is_list(games) do
    raw_scores(games)
    |> tiebreaks()
  end

  def with_players(scores, players) do
    Enum.reduce(players, %{}, fn p, acc ->
      Map.put(
        acc,
        p.id,
        Map.merge(Map.get(scores, p.id, %Score{}), %{player_id: p.id, player: p})
      )
    end)
  end

  def sort(scores) when is_map(scores) do
    Map.values(scores) |> sort()
  end

  def sort(scores) when is_list(scores) do
    scores
    |> Enum.sort_by(fn r -> r.player.rating end, :desc)
    |> Enum.sort_by(fn r -> r.nblack end, :desc)
    |> Enum.sort_by(fn r -> r.solkoff end, :desc)
    |> Enum.sort_by(fn r -> r.modmed end, :desc)
    |> Enum.sort_by(fn r -> r.score end, :desc)
  end

  @doc """
  Given a list of games, collapse into an individual score.
  """
  def raw_score_for_player(games, player_id) when is_list(games) do
    Enum.reduce(games, 0, fn g, acc ->
      cond do
        player_id == g.white_id -> acc + white_score_from_result(g.result)
        player_id == g.black_id -> acc + black_score_from_result(g.result)
        true -> acc
      end
    end)
  end

  @doc """
  Given the struct representing a game + a round, build out all available
  scores, including tiebreak scores that can be calculated at this point. The
  additional tiebreaks will be calculated later once the raw score mapping is
  completed.
  """
  def raw_scores(games) when is_list(games) do
    Enum.reduce(games, %{}, fn g, acc ->
      white_score = white_score_from_result(g.game.result)
      black_score = black_score_from_result(g.game.result)

      white_result = if is_nil(g.game.result), do: nil, else: white_score
      black_result = if is_nil(g.game.result), do: nil, else: black_score

      # update score map for white-side player
      acc =
        Map.update(
          acc,
          g.game.white_id,
          %Score{
            player_id: g.game.white_id,
            score: white_score,
            opponents: [g.game.black_id],
            results: [white_result],
            cumulative_sum: white_score * g.rnd,
            lastwhite: true
          },
          fn ex ->
            Map.merge(ex, %{
              score: ex.score + white_score,
              opponents: ex.opponents ++ [g.game.black_id],
              results: ex.results ++ [white_result],
              cumulative_sum: ex.cumulative_sum + white_score * g.rnd,
              lastwhite: true
            })
          end
        )

      # update score map for black-side player
      acc =
        Map.update(
          acc,
          g.game.black_id,
          %Score{
            player_id: g.game.black_id,
            score: black_score,
            opponents: [g.game.white_id],
            results: [black_result],
            cumulative_sum: black_score * g.rnd,
            nblack: 1,
            lastwhite: false
          },
          fn ex ->
            Map.merge(ex, %{
              score: ex.score + black_score,
              opponents: ex.opponents ++ [g.game.white_id],
              results: ex.results ++ [black_result],
              cumulative_sum: ex.cumulative_sum + black_score * g.rnd,
              nblack: ex.nblack + 1,
              lastwhite: false
            })
          end
        )

      acc
    end)
  end

  @doc """
  Calculates a variety of known tiebreaks. For a detailed breakdown of how these
  work in practice, see:
  https://midwestchess.com/pdf/USCF_ChessTie-Break_%20Systems.pdf
  """
  def tiebreaks(scores) when is_map(scores) do
    for {k, %Score{} = v} <- scores,
        into: %{},
        do: {
          k,
          Map.merge(v, %{
            cumulative_opp: cumulative_opp(v, scores),
            solkoff: solkoff(v, scores),
            modmed: modified_median(v, scores)
          })
        }
  end

  @doc """
  Calculate the "Modified Median" tiebreaker: drop lowest/highest depending on median value
  This is just the solkoff value subtracted by the appropriate score
  """
  def modified_median(%Score{} = v, scores) when is_map(scores) do
    opp_score = v.opponents

    {min_score, max_score} =
      Enum.map(opp_score, fn opp -> scores[opp].score end)
      |> Enum.min_max()

    cond do
      v.score > length(v.opponents) / 2 ->
        solkoff(v, scores) - min_score

      v.score < length(v.opponents) / 2 ->
        solkoff(v, scores) - max_score

      true ->
        solkoff(v, scores) - (min_score + max_score)
    end
  end

  @doc """
  Caculate the "cumulative opposition" tiebreaker: sum the cumulative sum of the
  score of each opponent.
  """
  def cumulative_opp(%Score{} = v, scores) when is_map(scores) do
    Enum.reduce(v.opponents, 0, fn opp, sum -> sum + scores[opp].cumulative_sum end)
  end

  @doc """
  Calculate the Solkoff tiebreaker (sum of opponent's scores, no discards).
  """
  def solkoff(%Score{} = v, scores) when is_map(scores) do
    Enum.reduce(v.opponents, 0, fn opp, sum -> sum + scores[opp].score end)
  end

  defp black_score_from_result(result) do
    case result do
      -1 -> 1
      0 -> 0.5
      1 -> 0
      nil -> 0
    end
  end

  defp white_score_from_result(result) do
    case result do
      -1 -> 0
      0 -> 0.5
      1 -> 1
      nil -> 0
    end
  end
end
