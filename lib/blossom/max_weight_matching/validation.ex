defmodule Blossom.MaxWeightMatching.Validation do
  @moduledoc """
  Input validation for the maximum weight matching algorithm.

  Validates edge list structure, types, and graph constraints.
  """

  # Maximum float weight to prevent overflow in dual variable calculations
  @float_limit Float.max_finite() / 4

  @doc """
  Validates that the input consists of valid data types and numerical ranges.

  Returns `:ok` if valid, or `{:error, reason}` if invalid.

  ## Checks
  - Input is a list
  - Each edge is a 3-tuple `{x, y, w}`
  - Endpoints `x` and `y` are non-negative integers
  - Weight `w` is an integer or finite float
  - Float weights are within safe range
  """
  @spec check_input_types(term()) :: :ok | {:error, String.t()}
  def check_input_types(edges) when is_list(edges) do
    validate_edges(edges)
  end

  def check_input_types(_edges) do
    {:error, "edges must be a list"}
  end

  @doc """
  Validates that the input is a valid graph without self-edges or duplicates.

  Returns `:ok` if valid, or `{:error, reason}` if invalid.

  ## Checks
  - No self-edges (x != y)
  - No duplicate edges
  """
  @spec check_input_graph(list()) :: :ok | {:error, String.t()}
  def check_input_graph(edges) do
    with :ok <- check_no_self_edges(edges),
         :ok <- check_no_duplicate_edges(edges) do
      :ok
    end
  end

  @doc """
  Removes edges with negative weight.

  This does not change the solution of the maximum-weight matching problem,
  but prevents complications in the algorithm.
  """
  @spec remove_negative_weight_edges(list()) :: list()
  def remove_negative_weight_edges(edges) do
    Enum.filter(edges, fn {_x, _y, w} -> w >= 0 end)
  end

  # Private helpers

  defp validate_edges(edges) do
    Enum.reduce_while(edges, :ok, fn edge, :ok ->
      case validate_edge(edge) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp validate_edge(edge) when not is_tuple(edge) or tuple_size(edge) != 3 do
    {:error, "each edge must be specified as a 3-tuple"}
  end

  defp validate_edge({x, y, w}) do
    with :ok <- validate_endpoints(x, y),
         :ok <- validate_weight(w) do
      :ok
    end
  end

  defp validate_endpoints(x, y) when not is_integer(x) or not is_integer(y) do
    {:error, "edge endpoints must be integers"}
  end

  defp validate_endpoints(x, y) when x < 0 or y < 0 do
    {:error, "edge endpoints must be non-negative integers"}
  end

  defp validate_endpoints(_x, _y), do: :ok

  defp validate_weight(w) when is_integer(w), do: :ok

  defp validate_weight(w) when is_float(w) do
    cond do
      # Check for infinity: infinity is greater than max finite float
      w > @float_limit * 4 or w < -@float_limit * 4 ->
        {:error, "edge weights must be finite numbers"}

      w > @float_limit ->
        {:error, "floating point edge weights must be less than #{@float_limit}"}

      true ->
        :ok
    end
  end

  defp validate_weight(_w) do
    {:error, "edge weights must be integers or floating point numbers"}
  end

  defp check_no_self_edges(edges) do
    case Enum.find(edges, fn {x, y, _w} -> x == y end) do
      nil -> :ok
      _edge -> {:error, "self-edges are not supported"}
    end
  end

  defp check_no_duplicate_edges(edges) do
    normalized =
      edges
      |> Enum.map(fn {x, y, _w} -> if x < y, do: {x, y}, else: {y, x} end)
      |> Enum.sort()

    case find_duplicate(normalized) do
      nil -> :ok
      dup -> {:error, "duplicate edge #{inspect(dup)}"}
    end
  end

  defp find_duplicate([]), do: nil
  defp find_duplicate([_]), do: nil

  defp find_duplicate([a, a | _rest]), do: a
  defp find_duplicate([_ | rest]), do: find_duplicate(rest)
end
