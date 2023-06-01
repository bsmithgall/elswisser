defmodule ElswisserWeb.TournamentController do
  use ElswisserWeb, :controller

  import Phoenix.Controller

  alias Elswisser.Tournaments
  alias Elswisser.Scores
  alias Elswisser.Tournaments.Tournament

  plug :put_root_layout,
       [html: {ElswisserWeb.TournamentLayouts, :root}] when action in [:show, :edit, :crosstable]

  def index(conn, _params) do
    tournaments = Tournaments.list_tournaments()
    render(conn, :index, tournaments: tournaments)
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

  def show(conn, %{"id" => id}) do
    tournament = Tournaments.get_tournament_with_all!(id)

    conn
    |> put_layout(html: {ElswisserWeb.TournamentLayouts, :tournament})
    |> render(:show, tournament: tournament)
  end

  def edit(conn, %{"id" => id}) do
    tournament = Tournaments.get_tournament_with_all!(id)
    changeset = Tournaments.empty_changeset(tournament)

    conn
    |> put_layout(html: {ElswisserWeb.TournamentLayouts, :tournament})
    |> render(:edit, tournament: tournament, changeset: changeset)
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

  def crosstable(conn, %{"tournament_id" => id}) do
    tournament = Tournaments.get_tournament_with_all!(id)
    games = Tournaments.get_all_games_in_tournament!(id)
    scores = Scores.calculate(games) |> Scores.with_players(tournament.players) |> Scores.sort()

    conn
    |> put_layout(html: {ElswisserWeb.TournamentLayouts, :tournament})
    |> render(:crosstable, tournament: tournament, games: games, scores: scores)
  end

  def scores(conn, %{"tournament_id" => id}) do
    tournament = Tournaments.get_tournament_with_all!(id)
    games = Tournaments.get_all_games_in_tournament!(id)
    scores = Scores.calculate(games) |> Scores.with_players(tournament.players) |> Scores.sort()

    conn
    |> put_layout(html: {ElswisserWeb.TournamentLayouts, :tournament})
    |> render(:scores, tournament: tournament, games: games, scores: scores)
  end
end
