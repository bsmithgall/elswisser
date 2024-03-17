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

  def render(%{id: _} = assigns) do
    ~H"""
    <div class="mb-4"><%= inspect(assigns.game) %></div>
    <div class="mb-4"><%= @session_id %></div>

    <div
      id="board-container"
      phx-hook="PlayGameHook"
      phx-value-color={@live_action}
      phx-value-white={@game.white}
      phx-value-black={@game.black}
      phx-value-sessionid={@session_id}
      phx-value-fen={@game.fen}
      phx-value-pgn={@game.pgn}
    >
      <span><%= @game.black %></span>
      <div id="board" class="w:40 md:w-96"></div>
      <span><%= @game.white %></span>
    </div>
    """
  end

  def render(_), do: ""

  def mount(%{"id" => id} = params, session, socket) do
    game = Store.join_game(id, session["live_socket_id"], socket.assigns.live_action)
    ElswisserWeb.Endpoint.subscribe(id)

    {:ok,
     socket
     |> assign(:id, id)
     |> assign(:game, game)
     |> assign(:black, params["black"])
     |> assign(:session_id, session["live_socket_id"])}
  end

  def mount(_, _, socket) do
    {:ok, redirect(socket, to: "/game/#{generate_game_id()}")}
  end

  def handle_event("move", %{"fen" => fen, "pgn" => pgn, "move" => move}, socket) do
    Store.update_game_position(socket.assigns.id, fen, pgn, move)
    send(self(), {"move", {fen, pgn, move}})
    {:noreply, socket}
  end

  def handle_info({"move", {fen, pgn, move}}, socket) do
    {:noreply, socket |> push_event("move-done", %{fen: fen, pgn: pgn, move: move})}
  end

  def handle_info(
        %Phoenix.Socket.Broadcast{topic: _, event: "move", payload: {fen, pgn, move}},
        socket
      ) do
    {:noreply, socket |> push_event("move-done", %{fen: fen, pgn: pgn, move: move})}
  end

  defp generate_game_id,
    do: :crypto.strong_rand_bytes(@id_length) |> Base.url_encode64() |> binary_part(0, @id_length)
end
