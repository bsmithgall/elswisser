defmodule Elswisser.Scores do
  @derive Jason.Encoder
  defstruct player_id: -1,
            score: -1,
            opponents: [],
            solkoff: 0,
            modmed: 0,
            cumulative_sum: 0,
            cumulative_opp: 0,
            nblack: 0

  def calculate(nil), do: calculate([])

  def calculate(games) when is_list(games) do
    raw_scores(games)
    |> tiebreaks()
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

      # update score map for white-side player
      acc =
        Map.update(
          acc,
          g.game.white,
          %Elswisser.Scores{
            player_id: g.game.white,
            score: white_score,
            opponents: [g.game.black],
            cumulative_sum: white_score * g.rnd
          },
          fn ex ->
            Map.merge(ex, %{
              score: ex.score + white_score,
              opponents: ex.opponents ++ [g.game.black],
              cumulative_sum: ex.cumulative_sum + white_score * g.rnd
            })
          end
        )

      # update score map for black-side player
      acc =
        Map.update(
          acc,
          g.game.black,
          %Elswisser.Scores{
            player_id: g.game.black,
            score: black_score,
            opponents: [g.game.white],
            cumulative_sum: black_score * g.rnd,
            nblack: 1
          },
          fn ex ->
            Map.merge(ex, %{
              score: ex.score + black_score,
              opponents: ex.opponents ++ [g.game.white],
              cumulative_sum: ex.cumulative_sum + black_score * g.rnd,
              nblack: ex.nblack + 1
            })
          end
        )

      acc
    end)
  end

  @doc """
  @TODO
  Calculates a variety of known tiebreaks. For a detailed breakdown of how these
  work in practice, see:
  https://midwestchess.com/pdf/USCF_ChessTie-Break_%20Systems.pdf
  """
  def tiebreaks(scores) when is_map(scores) do
    for {k, %Elswisser.Scores{} = v} <- scores,
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
  def modified_median(%Elswisser.Scores{} = v, scores) when is_map(scores) do
    opp_score = v.opponents

    {min_score, max_score} = Enum.map(opp_score, fn opp -> scores[opp].score end)
      |> Enum.min_max()

    cond do
      v.score > (length(v.opponents) / 2) ->
        solkoff(v, scores) - min_score
      v.score < (length(v.opponents) / 2) ->
        solkoff(v, scores) - max_score
      true ->
        solkoff(v, scores) - (min_score + max_score)
    end
  end



  @doc """
  Caculate the "cumulative opposition" tiebreaker: sum the cumulative sum of the
  score of each opponent.
  """
  def cumulative_opp(%Elswisser.Scores{} = v, scores) when is_map(scores) do
    Enum.reduce(v.opponents, 0, fn opp, sum -> sum + scores[opp].cumulative_sum end)
  end

  @doc """
  Calculate the Solkoff tiebreaker (sum of opponent's scores, no discards).
  """
  def solkoff(%Elswisser.Scores{} = v, scores) when is_map(scores) do
    Enum.reduce(v.opponents, 0, fn opp, sum -> sum + scores[opp].score end)
  end

  defp black_score_from_result(result) do
    case result do
      -1 -> 1
      0 -> 0.5
      1 -> 0
    end
  end

  defp white_score_from_result(result) do
    case result do
      -1 -> 0
      0 -> 0.5
      1 -> 1
    end
  end
end