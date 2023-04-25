defmodule Elswisser.Scores do
  @derive Jason.Encoder
  defstruct player_id: -1,
            score: -1,
            opponents: [],
            solkoff: 0,
            modmed: 0,
            cumsum: 0,
            cumopp: 0,
            nblack: 0

  def scores(nil), do: scores([])

  def scores(games) when is_list(games) do
    %{
      raw_scores: raw_scores(games)
    }
  end

  def raw_scores(nil), do: raw_scores([])

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
            cumsum: white_score * g.rnd
          },
          fn ex ->
            Map.merge(ex, %{
              score: ex.score + white_score,
              opponents: ex.opponents ++ [g.game.black],
              cumsum: ex.cumsum + white_score * g.rnd
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
            cumsum: black_score * g.rnd,
            nblack: 1
          },
          fn ex ->
            Map.merge(ex, %{
              score: ex.score + black_score,
              opponents: ex.opponents ++ [g.game.white],
              cumsum: ex.cumsum + black_score * g.rnd,
              nblack: ex.nblack + 1
            })
          end
        )

      acc
    end)
  end

  @doc """
  @TODO
  Calculates a variety of known tiebreaks:
  - *Modified Median*:
  - *Solkoff*:
  - *Cumulative of opposition*:
  """
  def tiebreaks(scores) when is_map(scores) do
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
