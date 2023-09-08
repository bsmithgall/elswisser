defmodule ElswisserWeb.TournamentController do
  use ElswisserWeb, :controller

  import Phoenix.Controller

  alias Elswisser.Tournaments
  alias Elswisser.Rounds
  alias Elswisser.Scores
  alias Elswisser.Tournaments.Tournament
  alias ElswisserWeb.Plugs.EnsureTournament

  plug EnsureTournament, "all" when action in [:show, :edit, :scores, :crosstable]
  plug EnsureTournament, "rounds" when action in [:stats]

  plug :fetch_games when action in [:scores, :crosstable]
  plug :calculate_scores when action in [:scores, :crosstable]

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

  def show(conn, _params) do
    conn
    |> put_layout(html: {ElswisserWeb.TournamentLayouts, :tournament})
    |> render(:show,
      tournament: conn.assigns[:tournament],
      current_round: conn.assigns[:current_round]
    )
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

  defp fetch_games(conn, _) do
    games = Tournaments.get_all_games_in_tournament!(conn.assigns[:tournament_id])
    assign(conn, :games, games)
  end

  defp calculate_scores(conn, _) do
    scores =
      Scores.calculate(conn.assigns[:games])
      |> Scores.with_players(conn.assigns[:tournament].players)
      |> Scores.sort()

    assign(conn, :scores, scores)
  end
end
