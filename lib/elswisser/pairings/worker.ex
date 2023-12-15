defmodule Elswisser.Pairings.Worker do
  use GenServer

  require Logger
  @timeout 10_000

  def start_link() do
    GenServer.start_link(__MODULE__, nil)
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def direct_call(pid, pairings) do
    GenServer.call(pid, {:do_pairings, pairings})
  end

  def pooled_call(pairings, :swiss) do
    Task.async(fn ->
      :poolboy.transaction(
        :pairing_worker,
        fn pid -> GenServer.call(pid, {:swiss, pairings}) end,
        @timeout
      )
    end)
    |> Task.await(@timeout)
  end

  @impl true
  def init(_) do
    path = [:code.priv_dir(:elswisser), "python"] |> Path.join()

    with {:ok, pid} = :python.start([{:python_path, to_charlist(path)}, {:python, ~c"python3"}]) do
      Logger.info("[#{__MODULE__}] Started python worker")
      {:ok, pid}
    end
  end

  @impl true
  def handle_call({:swiss, pairings}, _from, pid) do
    result = :python.call(pid, :mwmatching, :maximum_weight_matching, [pairings])
    Logger.info("[#{__MODULE__}] Handled pairing request")
    {:reply, {:ok, result}, pid}
  end
end
