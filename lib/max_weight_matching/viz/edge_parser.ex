defmodule MaxWeightMatching.Viz.EdgeParser do
  @moduledoc """
  Parses and formats edge definitions for the matching visualizer.

  Edges are entered as text, one per line: `x, y, weight`.
  """

  @doc """
  Parse a multi-line string of edge definitions into a list of `{x, y, weight}` tuples.

  Each line should contain three integers separated by commas and/or whitespace.
  Returns `{:ok, edges}` or `{:error, message}`.
  """
  @spec parse(String.t()) :: {:ok, list({integer(), integer(), integer()})} | {:error, String.t()}
  def parse(input) do
    lines =
      input
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    edges =
      Enum.map(lines, fn line ->
        parts =
          line
          |> String.replace(~r/[,\s]+/, " ")
          |> String.split(" ")
          |> Enum.map(&String.trim/1)
          |> Enum.reject(&(&1 == ""))

        case parts do
          [x, y, w] ->
            with {xi, ""} <- Integer.parse(x),
                 {yi, ""} <- Integer.parse(y),
                 {wi, ""} <- Integer.parse(w) do
              {:ok, {xi, yi, wi}}
            else
              _ -> {:error, "Invalid number in: #{line}"}
            end

          _ ->
            {:error, "Expected 3 values per line (x, y, weight), got: #{line}"}
        end
      end)

    errors = Enum.filter(edges, &match?({:error, _}, &1))

    if errors == [] do
      {:ok, Enum.map(edges, fn {:ok, e} -> e end)}
    else
      {:error, elem(hd(errors), 1)}
    end
  end

  @doc """
  Format a list of `{x, y, weight}` tuples as a newline-separated string.
  """
  @spec format(list({integer(), integer(), integer()})) :: String.t()
  def format(edges) do
    Enum.map_join(edges, "\n", fn {x, y, w} -> "#{x}, #{y}, #{w}" end)
  end

  @doc """
  Encode edges as a compact pipe-separated string for use in URL query params.

  ## Example

      iex> EdgeParser.encode([{0, 1, 10}, {2, 3, 8}])
      "0,1,10|2,3,8"
  """
  @spec encode(list({integer(), integer(), integer()})) :: String.t()
  def encode(edges) do
    Enum.map_join(edges, "|", fn {x, y, w} -> "#{x},#{y},#{w}" end)
  end

  @doc """
  Decode a pipe-separated edge string (from `encode/1`) back into edge tuples.

  Returns `{:ok, edges}` or `{:error, message}`.

  ## Example

      iex> EdgeParser.decode("0,1,10|2,3,8")
      {:ok, [{0, 1, 10}, {2, 3, 8}]}
  """
  @spec decode(String.t()) ::
          {:ok, list({integer(), integer(), integer()})} | {:error, String.t()}
  def decode(input) when is_binary(input) and input != "" do
    results =
      input
      |> String.split("|")
      |> Enum.map(fn segment ->
        case String.split(segment, ",") do
          [x, y, w] ->
            with {xi, ""} <- Integer.parse(x),
                 {yi, ""} <- Integer.parse(y),
                 {wi, ""} <- Integer.parse(w) do
              {:ok, {xi, yi, wi}}
            else
              _ -> {:error, "Invalid number in segment: #{segment}"}
            end

          _ ->
            {:error, "Expected 3 comma-separated values, got: #{segment}"}
        end
      end)

    case Enum.find(results, &match?({:error, _}, &1)) do
      nil -> {:ok, Enum.map(results, fn {:ok, e} -> e end)}
      {:error, msg} -> {:error, msg}
    end
  end

  def decode(_), do: {:error, "Empty or invalid edges parameter"}
end
