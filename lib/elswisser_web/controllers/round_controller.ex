defmodule ElswisserWeb.RoundController do
  use ElswisserWeb, :controller

  alias Elswisser.Rounds

  plug(:fetch_round)
  plug(:ensure_round_in_tournament when action in [:show, :pairings])

  plug ElswisserWeb.Plugs.EnsureTournament,
       "rounds" when action in [:show, :pairings]

  plug(
    :put_root_layout,
    [html: {ElswisserWeb.TournamentLayouts, :root}] when action in [:show, :pairings]
  )

  def show(conn, %{"id" => id}) do
    conn
    |> put_layout(html: {ElswisserWeb.TournamentLayouts, :tournament})
    |> render(:show,
      round: conn.assigns[:round],
      tournament: conn.assigns[:tournament],
      current_round: conn.assigns[:current_round],
      active: "round-#{id}"
    )
  end

  def create(conn, %{"tournament_id" => tournament_id, "number" => number}) do
    case Rounds.create_round(%{number: number, tournament_id: tournament_id, status: :pairing}) do
      {:ok, round} ->
        conn
        |> put_flash(:info, "Round created successfully.")
        |> redirect(to: ~p"/tournaments/#{round.tournament_id}/rounds/#{round.id}")

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Found errors: #{changeset.errors}")
        |> redirect(external: current_url(conn))
    end
  end

  def pairings(conn, %{"id" => id}) do
    conn
    |> put_layout(html: {ElswisserWeb.TournamentLayouts, :tournament})
    |> render(:pairing,
      round: conn.assigns[:round],
      tournament: conn.assigns[:tournament],
      current_round: conn.assigns[:current_round],
      active: "round-#{id}"
    )
  end

  def update(conn, %{"round" => round_params}) do
    case Rounds.update_round(conn.assigns[:round], round_params) do
      {:ok, round} ->
        conn
        |> put_flash(:info, "Round updated successfully.")
        |> redirect(to: ~p"/tournaments/#{round.tournament}/rounds/#{round}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, round: conn.assigns[:round], changeset: changeset)
    end
  end

  defp fetch_round(conn, _) do
    case Rounds.get_round(conn.params["id"]) do
      nil -> not_found(conn)
      rnd -> assign(conn, :round, rnd)
    end
  end

  defp ensure_round_in_tournament(conn, _) do
    case Integer.to_string(conn.assigns[:round].tournament_id) == conn.params["tournament_id"] do
      true -> conn
      false -> not_found(conn)
    end
  end

  defp not_found(conn) do
    conn
    |> put_status(404)
    |> put_view(ElswisserWeb.ErrorHTML)
    |> render("404.html")
    |> halt()
  end
end
