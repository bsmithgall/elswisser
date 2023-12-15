defmodule Elswisser.Pairings.BracketWorker do
  def generate_bracket(players) do
    with {:ok, raw} <- generate_async(players),
         {:ok, decoded} <- Jason.decode(raw) do
      {:ok, decoded}
    else
      {:error, msg} -> {:error, msg}
    end
  end

  def generate_async(players) do
    Task.async(fn ->
      start(players |> Enum.map(& &1.id) |> Jason.encode!()) |> wait(nil)
    end)
    |> Task.await()
  end

  defp start(players) do
    exe_path = System.find_executable("node")
    script_path = [:code.priv_dir(:elswisser), "nodejs", "bracket.js"] |> Path.join()

    Port.open({:spawn_executable, exe_path}, [
      :stderr_to_stdout,
      :binary,
      :exit_status,
      args: [script_path, players]
    ])
  end

  defp wait(port, results) do
    receive do
      {port, {:data, data}} ->
        wait(port, data)

      {^port, {:exit_status, 0}} ->
        {:ok, results}

      {^port, {:exit_status, _}} ->
        {:error, results}
    after
      5_000 -> {:error, :timeout}
    end
  end
end
