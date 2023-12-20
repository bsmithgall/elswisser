defmodule ElswisserWeb.Tournaments.GamesController do
  use ElswisserWeb, :controller

  alias Elswisser.Matches
  alias ElswisserWeb.Plugs.EnsureTournament

  plug EnsureTournament, "all" when action in [:index]
  plug EnsureTournament, "rounds" when action in [:current]

  def index(conn, _params) do
    conn
    |> put_layout(html: {ElswisserWeb.TournamentLayouts, :tournament})
    |> render(:index,
      tournament: conn.assigns.tournament,
      current_round: conn.assigns.current_round,
      active: "games"
    )
  end

  def current(conn, _params) do
    active_games =
      Matches.get_active_matches(conn.assigns.tournament.id, :mini)
      |> Enum.group_by(& &1.round_display_name)

    conn
    |> put_layout(html: {ElswisserWeb.TournamentLayouts, :tournament})
    |> render(:current,
      tournament: conn.assigns.tournament,
      current_round: conn.assigns.current_round,
      active_games: active_games,
      active: "current-games"
    )
  end
end
