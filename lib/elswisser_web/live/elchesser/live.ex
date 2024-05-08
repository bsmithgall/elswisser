defmodule ElswisserWeb.Elchesser.Live do
  use ElswisserWeb, :live_view

  import ElchesserWeb.Game

  def render(assigns) do
    ~H"""
    <.game game={@game} move_map={@move_map} next_click={@next_click} />
    """
  end

  def mount(_, _, socket) do
    socket =
      socket
      |> assign(game: Elchesser.Game.new())
      |> assign(move_map: %{})
      |> assign(next_click: "start")

    {:ok, socket}
  end

  def handle_event("square-click", %{"file" => f, "rank" => r, "type" => "start"}, socket) do
    loc = {String.to_integer(f), String.to_integer(r)}

    socket =
      socket
      |> assign(
        move_map:
          Elchesser.Square.legal_moves(loc, socket.assigns.game)
          |> Enum.reduce(%{}, fn move, acc -> Map.put(acc, move.to, move) end)
      )
      |> assign(start: loc)
      |> assign(next_click: "stop")

    {:noreply, socket}
  end

  def handle_event("square-click", %{"file" => f, "rank" => r, "type" => "stop"}, socket) do
    loc = {String.to_integer(f), String.to_integer(r)}

    socket =
      case Elchesser.Game.move(
             socket.assigns.game,
             Map.get(socket.assigns.move_map, loc)
           ) do
        {:ok, game} -> assign(socket, game: game)
        {:error, _} -> socket
      end
      |> assign(move_map: %{})
      |> assign(start: nil)
      |> assign(next_click: "start")

    {:noreply, socket}
  end
end
