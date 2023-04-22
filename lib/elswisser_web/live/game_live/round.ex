defmodule ElswisserWeb.GameLive.Round do
  use ElswisserWeb, :live_view

  alias Elswisser.Rounds

  @impl true
  def mount(_params, session, socket) do
    games = Rounds.get_games_for_round!(session["round_id"])

    {:ok, socket |> assign(:games, games), layout: false}
  end

  @impl true
  def handle_event("save-result", params, socket) do
    game = Rounds.get_game!(params["id"])

    case Rounds.update_game(game, params) do
      {:ok, _game} ->
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = _changeset} ->
        {:error, socket}
    end
  end
end
