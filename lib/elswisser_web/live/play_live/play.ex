defmodule ElswisserWeb.PlayLive.Play do
  @moduledoc """
    TODO:
    - Create games in active game registry
    - Update their FENs when we get new information
    - Clear them out when done
    - Allow white player, black player, watchers
  """
  use ElswisserWeb, :live_view

  alias ElswisserWeb.PlayLive.Store

  @id_length 8
  @active %{}

  def render(%{id: _} = assigns) do
    ~H"""
    <div id="board-container" phx-hook="PlayGameHook" phx-value-color={@live_action}>
      <div id="board" class="w:40 md:w-96"></div>
    </div>
    """
  end

  def render(_), do: ""

  def mount(%{"id" => id} = params, session, socket) do
    Store.join_game(id, session["live_socket_id"], socket.assigns.live_action)

    ElswisserWeb.Endpoint.subscribe(id)

    {:ok,
     socket
     |> assign(:id, id)
     |> assign(:black, params["black"])
     |> assign(:session_id, session["live_socket_id"])}
  end

  def mount(_, _, socket) do
    {:ok, redirect(socket, to: "/game/#{generate_game_id()}")}
  end

  def handle_event("move", %{"fen" => fen, "move" => move}, socket) do
    Store.update_game_position(socket.assigns.id, fen, move)
    send(self(), {"move", {fen, move}})
    {:noreply, socket}
  end

  def handle_info({"move", {fen, move}}, socket) do
    {:noreply, socket |> push_event("move-done", %{fen: fen, move: move})}
  end

  def handle_info(
        %Phoenix.Socket.Broadcast{topic: _, event: "move", payload: {fen, move}},
        socket
      ) do
    {:noreply, socket |> push_event("move-done", %{fen: fen, move: move})}
  end

  defp generate_game_id,
    do: :crypto.strong_rand_bytes(@id_length) |> Base.url_encode64() |> binary_part(0, @id_length)
end
