defmodule ElswisserWeb.RoundController do
  use ElswisserWeb, :controller

  alias Elswisser.Rounds

  plug :put_root_layout, [html: {ElswisserWeb.TournamentLayouts, :root}] when action in [:show]

  def show(conn, %{"tournament_id" => tournament_id, "id" => id}) do
    rnd = Rounds.get_round!(id)

    if Integer.to_string(rnd.tournament_id) != tournament_id do
      conn
      |> put_status(404)
      |> put_view(ElswisserWeb.ErrorHTML)
      |> render("404.html")
      |> halt()
    end

    games = Rounds.get_games_for_round!(id)
    tournament = Elswisser.Tournaments.get_tournament_with_players!(tournament_id)

    player_map =
      tournament.players
      |> Map.new(fn p -> {p.id, p} end)

    conn
    |> put_layout(html: {ElswisserWeb.TournamentLayouts, :tournament})
    |> render(:show, round: rnd, games: games, tournament: tournament, player_map: player_map)
  end

  def edit(conn, %{"id" => id}) do
    round = Rounds.get_round!(id)
    changeset = Rounds.change_round(round)

    render(conn, :edit, round: round, changeset: changeset)
  end

  def update(conn, %{"id" => id, "round" => round_params}) do
    round = Rounds.get_round!(id)

    case Rounds.update_round(round, round_params) do
      {:ok, round} ->
        conn
        |> put_flash(:info, "Round updated successfully.")
        |> redirect(to: ~p"/tournaments/#{round.tournament}/rounds/#{round}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, round: round, changeset: changeset)
    end
  end
end
