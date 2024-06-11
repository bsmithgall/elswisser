defmodule Elchesser.Engine.Server do
  @moduledoc """
  GenServer wrapper for interacting with a given engine. The engine evaluates
  a given position and offers a single move.

  TODO:
    - Store the engines at game join time instead of passing them around
    - Use a custom Pub/Sub instead of ElswisserWeb.Endpoint
  """

  use GenServer

  def start_link(), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  @impl true
  def init(_), do: {:ok, %{}}

  # public api

  def make_move(game_id, game, engine) do
    GenServer.cast(__MODULE__, {:make_move, {game_id, game, engine}})
  end

  # internal API

  @impl true
  def handle_cast({:make_move, {game_id, game, engine}}, state) do
    move = engine.move(game)
    ElswisserWeb.Endpoint.broadcast("engine:" <> game_id, "move", move)

    {:noreply, state}
  end
end
