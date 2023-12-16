defmodule Elswisser.Pairings.BracketWorker do
  def generate_bracket(players) do
    encoded = players |> Enum.map(& &1.id) |> Jason.encode!()

    with {:ok, raw} <- generate_async(encoded),
         {:ok, decoded} <- Jason.decode(raw),
         {:ok, matches, rounds} <- parse(decoded) do
      {:ok, matches, rounds}
    else
      {:error, msg} -> {:error, msg}
    end
  end

  def parse(decoded) do
    {
      :ok,
      decoded["matches"],
      decoded["rounds"] |> Enum.map(fn {k, v} -> {String.to_integer(k), v} end) |> Enum.into(%{})
    }
  end

  def generate_async(players) do
    Task.async(fn -> start(players) end) |> Task.await()
  end

  defp start(players) do
    exe_path = System.find_executable("node")
    script_path = [:code.priv_dir(:elswisser), "nodejs", "bracket.js"] |> Path.join()

    case System.cmd(exe_path, [script_path, players]) do
      {raw, 0} -> {:ok, raw}
      {error, _} -> {:error, error}
    end
  end
end
