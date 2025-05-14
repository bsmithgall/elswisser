defmodule ElswisserWeb.Tournaments.TournamentController do
  use ElswisserWeb, :controller

  import Phoenix.Controller

  alias Elswisser.Rounds
  alias Elswisser.Tournaments
  alias Elswisser.Tournaments.Tournament
  alias ElswisserWeb.Plugs.EnsureTournament

  plug EnsureTournament, "all" when action in [:show, :edit]

  def index(conn, _params) do
    tournaments = Tournaments.list_tournaments()
    conn |> render(:index, tournaments: tournaments)
  end

  def new(conn, _params) do
    changeset = Tournaments.change_tournament(%Tournament{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"tournament" => tournament_params}) do
    case Tournaments.create_tournament(tournament_params) do
      {:ok, tournament} ->
        conn
        |> put_flash(:info, "Tournament created successfully.")
        |> redirect(to: ~p"/tournaments/#{tournament}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, _params) do
    active_round =
      conn.assigns[:tournament].rounds
      |> Enum.find(&Enum.member?([:playing, :pairing], &1.status))

    case active_round do
      nil ->
        conn
        |> put_layout(html: {ElswisserWeb.TournamentLayouts, :tournament})
        |> render("show_#{conn.assigns[:tournament].type}.html",
          tournament: conn.assigns[:tournament],
          current_round: conn.assigns[:current_round]
        )

      %Rounds.Round{id: id, tournament_id: tournament_id, status: :pairing} ->
        conn |> redirect(to: ~p"/tournaments/#{tournament_id}/rounds/#{id}/pairings")

      %Rounds.Round{id: id, tournament_id: tournament_id, status: :playing} ->
        conn |> redirect(to: ~p"/tournaments/#{tournament_id}/rounds/#{id}")
    end
  end

  def edit(conn, _params) do
    changeset = Tournaments.empty_changeset(conn.assigns[:tournament])

    conn
    |> put_layout(html: {ElswisserWeb.TournamentLayouts, :tournament})
    |> render(:edit,
      tournament: conn.assigns[:tournament],
      current_round: conn.assigns[:current_round],
      changeset: changeset
    )
  end

  def update(conn, %{"id" => id, "tournament" => tournament_params}) do
    tournament = Tournaments.get_tournament!(id)

    case Tournaments.update_tournament(tournament, tournament_params) do
      {:ok, tournament} ->
        conn
        |> put_flash(:info, "Tournament updated successfully.")
        |> redirect(to: ~p"/tournaments/#{tournament}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, tournament: tournament, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    tournament = Tournaments.get_tournament!(id)
    {:ok, _tournament} = Tournaments.delete_tournament(tournament)

    conn
    |> put_flash(:info, "Tournament deleted successfully.")
    |> redirect(to: ~p"/tournaments")
  end
end
