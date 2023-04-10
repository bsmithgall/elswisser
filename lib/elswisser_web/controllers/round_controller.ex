defmodule ElswisserWeb.RoundController do
  use ElswisserWeb, :controller

  alias Elswisser.Rounds

  def show(conn, %{"id" => id}) do
    round = Rounds.get_round!(id)
    render(conn, :show, round: round)
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
