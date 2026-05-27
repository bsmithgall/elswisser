defmodule ElswisserWeb.Elchesser.Computer do
  alias Elchesser.Game
  alias Elchesser.Engine
  use ElswisserWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket |> assign(phase: :setup)}
  end

  def render(%{phase: :setup} = assigns) do
    ~H"""
    <.simple_form for={%{}} phx-submit="start-game">
      <.input
        type="select"
        name="engine"
        label="Engine"
        options={Engine.all() |> Enum.map(&{&1.name(), &1})}
        value="Select one"
      />
      <.input type="radio" name="color" options={[{"White", "w"}, {"Black", "b"}]} value="w" />
      <:actions>
        <.button>Start game</.button>
      </:actions>
    </.simple_form>
    """
  end

  def render(assigns) do
    ~H"""
    <.live_component
      module={ElchesserWeb.LiveGame}
      id="live-game"
      game_id={@game_id}
      color={@color}
      game={@game}
    />
    """
  end

  def handle_event("start-game", %{"engine" => engine, "color" => color}, socket) do
    engine = Engine.from_string(engine)

    color =
      case color do
        "w" -> :w
        "b" -> :b
      end

    game_id = generate_id()
    :ok = ElswisserWeb.Endpoint.subscribe("board:" <> game_id)
    :ok = ElswisserWeb.Endpoint.subscribe("engine:" <> game_id)

    game = Game.new()

    if color == :b do
      Engine.Server.make_move(game_id, game, engine)
    end

    {:noreply,
     socket
     |> assign(phase: :playing, game: game, game_id: game_id, engine: engine, color: color)}
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
