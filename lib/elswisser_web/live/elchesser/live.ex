defmodule ElswisserWeb.Elchesser.Live do
  use ElswisserWeb, :live_view

  import ElchesserWeb.Game

  def render(assigns) do
    ~H"""
    <.game
      game={@game}
      move_map={@move_map}
      next_click={@next_click}
      active_square={@active_square}
      active_move={@active_move}
    />
    """
  end

  def mount(_, _, socket) do
    socket =
      socket
      |> assign(game: Elchesser.Game.new())
      |> assign(move_map: %{})
      |> assign(next_click: "start")
      |> assign(active_square: nil)
      |> assign(active_move: 1)

    {:ok, socket}
  end

  def handle_event("square-click", %{"file" => f, "rank" => r, "type" => "start"}, socket) do
    loc = {String.to_integer(f), String.to_integer(r)}
    {:noreply, assign_start_move(socket, loc)}
  end

  def handle_event("square-click", %{"file" => f, "rank" => r, "type" => "stop"}, socket) do
    loc = {String.to_integer(f), String.to_integer(r)}

    socket =
      case Elchesser.Game.move(socket.assigns.game, Map.get(socket.assigns.move_map, loc)) do
        {:ok, game} ->
          socket |> assign(game: game) |> assign_stop_move()

        {:error, err} when err in [:invalid_to_color, :invalid_from_color, :no_move_provided] ->
          assign_start_move(socket, loc)

        {:error, _} ->
          assign_stop_move(socket)
      end

    {:noreply, socket}
  end

  defp assign_start_move(socket, loc) do
    socket
    |> assign(move_map: get_move_map(loc, socket))
    |> assign(start: loc)
    |> assign(next_click: "stop")
    |> assign(active_square: get_active_square(loc, socket))
  end

  defp assign_stop_move(socket) do
    socket
    |> assign(move_map: %{})
    |> assign(start: nil)
    |> assign(next_click: "start")
    |> assign(active_square: nil)
    |> assign(active_move: length(socket.assigns.game.moves) + 1)
  end

  defp get_move_map(loc, socket) do
    Elchesser.Square.legal_moves(loc, socket.assigns.game)
    |> Enum.reduce(%{}, fn move, acc -> Map.put(acc, move.to, move) end)
  end

  defp get_active_square(loc, socket) do
    square = Elchesser.Game.get_square(socket.assigns.game, loc)

    if Elchesser.Piece.color_match?(square.piece, socket.assigns.game.active),
      do: square,
      else: nil
  end
end
