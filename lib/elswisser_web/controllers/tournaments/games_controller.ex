defmodule ElswisserWeb.Tournaments.GamesController do
  use ElswisserWeb, :controller

  alias ElswisserWeb.Plugs.EnsureTournament

  plug EnsureTournament, "all"

  def index(conn, _params) do
    conn
    |> put_layout(html: {ElswisserWeb.TournamentLayouts, :tournament})
    |> render(:index,
      tournament: conn.assigns[:tournament],
      current_round: conn.assigns[:current_round],
      active: "games"
    )
  end
end
