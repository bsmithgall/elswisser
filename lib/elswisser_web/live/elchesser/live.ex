defmodule ElswisserWeb.Elchesser.Live do
  use ElswisserWeb, :live_view

  import ElchesserWeb.Game

  alias Elchesser.{Game, Fen, Piece, Square}

  def render(assigns) do
    ~H"""
    <.game
      board={@board}
      active_color={@game.active}
      moves={@moves}
      white_captures={Game.captures(@game, :w)}
      black_captures={Game.captures(@game, :b)}
      move_map={@move_map}
      next_click={@next_click}
      active_square={@active_square}
      active_move={@active_move}
      orientation={@orientation}
    />
    """
  end

  def mount(_, _, socket) do
    game = Game.new()

    socket =
      socket
      |> assign_game_parts(game)
      |> assign(disable_moves: false)
      |> assign(move_map: %{})
      |> assign(next_click: "start")
      |> assign(active_square: nil)
      |> assign(active_move: 0)
      |> assign(orientation: :w)

    {:ok, socket}
  end

  def handle_event("square-click", %{"file" => f, "rank" => r, "type" => "start"}, socket) do
    loc = {String.to_integer(f), String.to_integer(r)}
    {:noreply, assign_start_move(socket, loc)}
  end

  def handle_event("square-click", %{"file" => f, "rank" => r, "type" => "stop"}, socket) do
    loc = {String.to_integer(f), String.to_integer(r)}

    socket =
      case Game.move(socket.assigns.game, Map.get(socket.assigns.move_map, loc)) do
        {:ok, game} ->
          socket
          |> assign_game_parts(game)
          |> assign_stop_move()

        {:error, err} when err in [:invalid_to_color, :invalid_from_color, :no_move_provided] ->
          assign_start_move(socket, loc)

        {:error, _} ->
          assign_stop_move(socket)
      end

    {:noreply, socket}
  end

  def handle_event("view-game-at", %{"idx" => idx}, socket) do
    game = socket.assigns.game
    game_length = length(game.moves)
    idx = String.to_integer(idx) |> clamp(game_length)

    to_display = Enum.at(game.fens, idx) |> Fen.parse()

    {:noreply,
     socket
     |> assign(active_move: idx + 1)
     |> assign(disable_moves: idx + 1 != game_length)
     |> assign(board: to_display.board)}
  end

  def handle_event("flip-board", %{"current" => "w"}, socket) do
    {:noreply, socket |> assign(orientation: :b)}
  end

  def handle_event("flip-board", %{"current" => "b"}, socket) do
    {:noreply, socket |> assign(orientation: :w)}
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
    |> assign(active_move: length(socket.assigns.game.moves))
  end

  defp assign_game_parts(socket, %Game{} = game) do
    socket
    |> assign(game: game)
    |> assign(board: game.board)
    |> assign(moves: game.moves)
    |> assign(white_captures: Game.captures(game, :w))
    |> assign(black_captures: Game.captures(game, :b))
  end

  defp get_move_map(loc, socket) do
    if socket.assigns.disable_moves,
      do: %{},
      else:
        Square.legal_moves(loc, socket.assigns.game)
        |> Enum.reduce(%{}, fn move, acc -> Map.put(acc, move.to, move) end)
  end

  defp get_active_square(loc, socket) do
    square = Game.get_square(socket.assigns.game, loc)

    if Piece.color_match?(square.piece, socket.assigns.game.active),
      do: square,
      else: nil
  end

  defp clamp(idx, _) when idx < 0, do: 0
  defp clamp(idx, len) when idx > len, do: len
  defp clamp(idx, _), do: idx
end
