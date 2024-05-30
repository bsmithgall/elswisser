defmodule ElchesserWeb.LiveGame do
  use Phoenix.LiveComponent

  import ElchesserWeb.Game

  alias Elchesser.{Game, Fen, Piece, Square}

  def render(assigns) do
    ~H"""
    <div id={@game_id}>
      <.game
        target={"\##{@game_id}"}
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
    </div>
    """
  end

  def mount(socket) do
    game = Game.new()

    socket =
      socket
      |> assign(game_id: generate_id())
      |> assign(orientation: :w)
      |> assign(disable_moves: false)
      |> assign_game_parts(game)
      |> assign_stop_move()

    {:ok, socket}
  end

  def update(%{pgn: pgn}, socket) when not is_nil(pgn) do
    {:ok, game} = Elchesser.Pgn.parse(pgn)
    {:ok, socket |> assign_game_parts(game) |> assign(active_move: length(game.moves))}
  end

  def update(_, socket), do: {:ok, socket}

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
    idx = String.to_integer(idx)
    {:noreply, socket |> assign_move_navigation(idx)}
  end

  def handle_event("kb-view-game-at", %{"key" => "ArrowLeft"}, socket) do
    idx = socket.assigns.active_move - 2
    {:noreply, socket |> assign_move_navigation(idx)}
  end

  def handle_event("kb-view-game-at", %{"key" => "ArrowRight"}, socket) do
    idx = socket.assigns.active_move
    {:noreply, socket |> assign_move_navigation(idx)}
  end

  def handle_event("kb-view-game-at", %{"key" => "ArrowUp"}, socket) do
    idx = 0
    {:noreply, socket |> assign_move_navigation(idx)}
  end

  def handle_event("kb-view-game-at", %{"key" => "ArrowDown"}, socket) do
    idx = game_length(socket) - 1
    {:noreply, socket |> assign_move_navigation(idx)}
  end

  def handle_event("kb-view-game-at", _, socket), do: {:noreply, socket}

  def handle_event("flip-board", %{"current" => "w"}, socket) do
    {:noreply, socket |> assign(orientation: :b)}
  end

  def handle_event("flip-board", %{"current" => "b"}, socket) do
    {:noreply, socket |> assign(orientation: :w)}
  end

  def assign_game_parts(socket, %Game{} = game) do
    socket
    |> assign(game: game)
    |> assign(board: game.board)
    |> assign(moves: game.moves)
    |> assign(white_captures: Game.captures(game, :w))
    |> assign(black_captures: Game.captures(game, :b))
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

  def assign_move_navigation(socket, idx) do
    game_length = game_length(socket)
    idx = clamp(idx, game_length - 1)
    to_display = Enum.at(socket.assigns.game.fens, idx) |> Fen.parse()

    socket
    |> assign(active_move: idx + 1)
    |> assign(disable_moves: idx + 1 != game_length(socket))
    |> assign(board: to_display.board)
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

  defp game_length(socket), do: length(socket.assigns.game.moves)

  defp clamp(idx, _) when idx < 0, do: 0
  defp clamp(idx, len) when idx > len, do: len
  defp clamp(idx, _), do: idx

  defp generate_id() do
    :crypto.strong_rand_bytes(6) |> Base.url_encode64() |> binary_part(0, 6)
  end
end
