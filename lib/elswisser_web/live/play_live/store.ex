defmodule ElswisserWeb.PlayLive.Store do
  alias ElswisserWeb.PlayLive.Game

  use GenServer

  def start_link(), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  @impl true
  def init(_) do
    {:ok, %{}}
  end

  # public api
  def join_game(game_id, player_id, :white) do
    GenServer.cast(__MODULE__, {:player, {game_id, player_id, :white}})
  end

  def join_game(game_id, player_id, :black) do
    GenServer.cast(__MODULE__, {:player, {game_id, player_id, :black}})
  end

  def update_game_position(game_id, fen, move) do
    GenServer.call(__MODULE__, {:move, {game_id, fen, move}})
  end

  def get_game_sync(game_id) do
    GenServer.call(__MODULE__, {:fetch, game_id})
  end

  # internal api
  @impl true
  def handle_call({:fetch, game_id}, _from, state) do
    {:reply, :ok, Map.get(state, game_id)}
  end

  @impl true
  def handle_call({:move, {game_id, fen, move}}, _from, state) do
    state =
      Map.update!(state, game_id, fn existing ->
        Map.merge(existing, %{fen: fen})
      end)

    ElswisserWeb.Endpoint.broadcast(game_id, "move", {fen, move})

    {:reply, :ok, state}
  end

  @impl true
  def handle_cast({:player, {game_id, player_id, :white}}, state) do
    {:noreply,
     Map.update(state, game_id, %Game{white: player_id}, fn existing ->
       if is_nil(existing.white), do: Map.merge(existing, %{white: player_id}), else: existing
     end)}
  end

  @impl true
  def handle_cast({:player, {game_id, player_id, :black}}, state) do
    {:noreply,
     Map.update(state, game_id, %Game{black: player_id}, fn existing ->
       if is_nil(existing.black), do: Map.merge(existing, %{black: player_id}), else: existing
     end)}
  end
end
