defmodule ElswisserWeb.RosterController do
  use ElswisserWeb, :controller

  alias Elswisser.Tournaments
  alias Elswisser.Players

  plug ElswisserWeb.Plugs.EnsureTournament, "rounds" when action in [:index]

  def index(conn, %{"tournament_id" => id}) do
    changeset = Tournaments.empty_changeset(conn.assigns[:tournament])
    {in_players, out_players} = Tournaments.get_roster(id)

    new_player = Players.change_player(%Players.Player{})

    conn
    |> put_layout(html: {ElswisserWeb.TournamentLayouts, :tournament})
    |> render(:index,
      tournament: conn.assigns[:tournament],
      current_round: conn.assigns[:current_round],
      active: "roster",
      changeset: changeset,
      in_players: in_players,
      out_players: out_players,
      new_player: new_player
    )
  end

  def update(conn, %{"tournament_id" => id, "player_ids" => player_ids}) do
    tournament = Tournaments.get_tournament!(id)

    case Tournaments.update_tournament(tournament, %{player_ids: player_ids}) do
      {:ok, tournament} ->
        conn
        |> put_flash(:info, "Tournament updated successfully.")
        |> redirect(to: ~p"/tournaments/#{tournament}/roster")

      {:error, %Ecto.Changeset{} = changeset} ->
        {in_players, out_players} = Tournaments.get_roster(id)
        new_player = Players.change_player(%Players.Player{})

        render(conn, :index,
          tournament: tournament,
          changeset: changeset,
          in_players: in_players,
          out_players: out_players,
          new_player: new_player
        )
    end
  end
end
