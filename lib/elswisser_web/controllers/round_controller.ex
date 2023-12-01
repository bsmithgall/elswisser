defmodule ElswisserWeb.RoundController do
  use ElswisserWeb, :controller

  alias Elswisser.Tournaments
  alias Elswisser.Rounds

  plug(:fetch_round when action not in [:create])
  plug(:ensure_round_in_tournament when action not in [:create])

  plug(
    ElswisserWeb.Plugs.EnsureTournament,
    "all" when action in [:show, :pairings, :create, :finalize]
  )

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
    case(Tournaments.create_next_round(conn.assigns[:tournament], number)) do
      {:ok, rnd} ->
        redirect_to =
          if conn.assigns[:tournament].type == :swiss,
            do: ~p"/tournaments/#{rnd.tournament_id}/rounds/#{rnd.id}/pairings",
            else: ~p"/tournaments/#{rnd.tournament_id}"

        conn
        |> put_flash(:info, "Round created successfully.")
        |> redirect(to: redirect_to)

      :finished ->
        conn
        |> put_flash(:error, "Could not create new round, tournament is over!")
        |> redirect(to: ~p"/tournaments/#{tournament_id}/scores")

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Found errors: #{changeset.errors}")
        |> redirect(external: current_url(conn))
    end
  end

  def pairings(conn, %{"id" => id, "tournament_id" => tournament_id}) do
    if conn.assigns[:tournament].type != :swiss do
      conn
      |> put_flash(:info, "Cannot manually set pairings for non-swiss tournaments!")
      |> redirect(to: ~p"/tournaments/#{tournament_id}/rounds/#{id}")
    end

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

  def finalize(conn, %{"tournament_id" => tournament_id, "id" => id}) do
    # @TODO: wrap all of this in a transaction via Ecto.Multi
    with {_count, nil} <- Rounds.draw_unfinished(id),
         {:ok, _update} <- Rounds.update_ratings_after_round(id),
         {:ok, rnd} <- Rounds.set_complete(conn.assigns[:round]),
         {:ok, next_round} <- Tournaments.create_next_round(conn.assigns[:tournament], rnd.number) do
      conn
      |> put_flash(
        :info,
        "Round successfully completed. Pairings players for round #{next_round.number}."
      )
      |> redirect(to: ~p"/tournaments/#{tournament_id}/rounds/#{next_round}/pairings")
    else
      :finished ->
        conn
        |> put_flash(:info, "Tournament has finished!")
        |> redirect(to: ~p"/tournaments/#{tournament_id}/scores")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Something went wrong finalizing the round: #{reason}")
        |> redirect(to: ~p"/tournaments/#{tournament_id}/rounds/#{id}")
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
