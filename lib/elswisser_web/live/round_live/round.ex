defmodule ElswisserWeb.RoundLive.Round do
  use ElswisserWeb, :live_view

  alias Elswisser.Games

  @impl true
  def mount(_params, session, socket) do
    {:ok, socket |> assign(:games, fetch_games(session["round_id"])), layout: false}
  end

  @impl true
  def handle_event("save-result", params, socket) do
    game = Games.get_game!(params["id"])

    case Games.update_game(game, params) do
      {:ok, game} ->
        {:noreply, socket |> assign(:games, fetch_games(game.round_id))}

      {:error, %Ecto.Changeset{} = _changeset} ->
        {:error, socket}
    end
  end

  defp fetch_games(round_id) do
    Games.get_games_for_round!(round_id)
  end
end
