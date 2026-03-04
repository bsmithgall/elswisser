defmodule Elswisser.Pairings.Worker do
  use GenServer

  require Logger

  @timeout 10_000

  def start_link do
    GenServer.start_link(__MODULE__, nil)
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def direct_call(pid, pairings) do
    GenServer.call(pid, {:swiss, pairings})
  end

  def pooled_call(pairings, :swiss) do
    :poolboy.transaction(
      :pairing_worker,
      fn pid -> GenServer.call(pid, {:swiss, pairings}) end,
      @timeout
    )
  end

  @impl true
  def init(_) do
    {:ok, nil}
  end

  @impl true
  def handle_call({:swiss, pairings}, _from, state) do
    result = MaxWeightMatching.maximum_weight_matching(pairings)
    Logger.info("[#{__MODULE__}] Handled pairing request")
    {:reply, {:ok, result}, state}
  end
end
