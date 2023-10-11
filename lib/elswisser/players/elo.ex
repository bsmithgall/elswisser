defmodule Elswisser.Players.ELO do
  def recalculate({p1rating, p1k}, {p2rating, p2k}, result) do
    {
      recalculate(p1rating, p2rating, p1k, result),
      recalculate(p2rating, p1rating, p2k, invert(result))
    }
  end

  @doc """
  Recalculate ratings after a match
  """
  def recalculate(a, b, k, result) do
    change = round(k * (to_score(result) - expected(a, b)))

    case above_floor(a + change) do
      {:yes, rating} -> {rating, change}
      {:no, rating} -> {rating, 0}
    end
  end

  @doc """
  Calculate expected change based on two players a and b. See: https://en.wikipedia.org/wiki/Elo_rating_system
  """
  def expected(a, b) when is_integer(a) and is_integer(b) do
    1 / (1 + :math.pow(10, (b - a) / 400))
  end

  defp to_score(result) do
    case result do
      1 -> 1
      0 -> 0.5
      -1 -> 0
    end
  end

  defp invert(result) do
    case result do
      1 -> -1
      0 -> 0
      -1 -> 1
    end
  end

  defp above_floor(adjusted) do
    if 100 > adjusted, do: {:no, 100}, else: {:yes, adjusted}
  end
end
