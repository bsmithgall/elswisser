defmodule ElswisserWeb.Tournaments.StatsController do
  use ElswisserWeb, :controller

  alias Elswisser.Rounds
  alias Elswisser.Scores
  alias ElswisserWeb.Plugs.EnsureTournament

  plug EnsureTournament, "all" when action not in [:stats]
  plug EnsureTournament, "rounds" when action in [:stats]

  plug :calculate_scores when action not in [:stats]

  def crosstable(conn, _params) do
    conn
    |> put_layout(html: {ElswisserWeb.TournamentLayouts, :tournament})
    |> render(:crosstable,
      tournament: conn.assigns[:tournament],
      current_round: conn.assigns[:current_round],
      games: conn.assigns[:games],
      scores: conn.assigns[:scores],
      active: "crosstable"
    )
  end

  def scores(conn, _params) do
    conn
    |> put_layout(html: {ElswisserWeb.TournamentLayouts, :tournament})
    |> render(:scores,
      tournament: conn.assigns[:tournament],
      current_round: conn.assigns[:current_round],
      games: conn.assigns[:games],
      scores: conn.assigns[:scores],
      active: "scores"
    )
  end

  def stats(conn, _) do
    {round_stats, tourn_stats} = Rounds.get_stats_for_tournament(conn.assigns[:tournament_id])

    conn
    |> put_layout(html: {ElswisserWeb.TournamentLayouts, :tournament})
    |> render(:stats, stats: round_stats, tournament_stats: tourn_stats, active: "stats")
  end

  defp calculate_scores(conn, _) do
    scores =
      Scores.calculate(conn.assigns[:tournament])
      |> Scores.with_players(conn.assigns[:tournament].players)
      |> Scores.sort()

    assign(conn, :scores, scores)
  end
end
