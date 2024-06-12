defmodule ElswisserWeb.Elchesser.Computer do
  use ElswisserWeb, :live_view

  def mount(_params, _session, socket) do
    engine = Elchesser.Engine.Random
    game_id = generate_id()

    :ok = ElswisserWeb.Endpoint.subscribe("board:" <> game_id)
    :ok = ElswisserWeb.Endpoint.subscribe("engine:" <> game_id)

    {:ok, socket |> assign(engine: engine) |> assign(game_id: game_id)}
  end

  def render(assigns) do
    ~H"""
    <.live_component module={ElchesserWeb.LiveGame} id="live-game" game_id={@game_id} />
    """
  end

  def handle_info(%{topic: "board:" <> game_id, payload: game}, socket) do
    Elchesser.Engine.Server.make_move(game_id, game, socket.assigns.engine)
    {:noreply, socket}
  end

  def handle_info(%{topic: "engine:" <> _, payload: move}, socket) do
    send_update(ElchesserWeb.LiveGame, id: "live-game", move: move, from_engine: true)
    {:noreply, socket}
  end

  defp generate_id() do
    :crypto.strong_rand_bytes(6) |> Base.url_encode64() |> binary_part(0, 6)
  end
end
