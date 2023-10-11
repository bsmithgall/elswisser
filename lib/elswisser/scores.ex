defmodule Elswisser.Scores do
  alias Elswisser.Tournaments.Tournament
  alias Elswisser.Scores.Score
  alias Elswisser.Games.Game

  def calculate(nil), do: calculate([])

  def calculate(games) when is_list(games) do
    raw_scores(games)
    |> tiebreaks()
  end

  def calculate(%Tournament{} = tournament) do
    Enum.flat_map(tournament.rounds, fn r ->
      Enum.map(r.games, fn g -> %{game: g, rnd: r} end)
    end)
    |> calculate()
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
        player_id == g.white_id -> acc + Game.white_score(g)
        player_id == g.black_id -> acc + Game.black_score(g)
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
      # update score map for white-side player
      acc =
        Map.update(
          acc,
          g.game.white_id,
          Score.white(g.game, g.rnd),
          fn ex -> Score.merge_white(ex, g.game, g.rnd) end
        )

      # update score map for black-side player
      Map.update(
        acc,
        g.game.black_id,
        Score.black(g.game, g.rnd),
        fn ex -> Score.merge_black(ex, g.game, g.rnd) end
      )
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
        max(solkoff(v, scores) - min_score, 0)

      v.score < length(v.opponents) / 2 ->
        max(solkoff(v, scores) - max_score, 0)

      true ->
        max(solkoff(v, scores) - (min_score + max_score), 0)
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
end
