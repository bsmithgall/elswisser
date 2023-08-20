defmodule Elswisser.Players.ELO do
  @doc """
  Recalculate ratings after a match
  """
  def recalculate(a, b, k, result) do
    change = k * (to_score(result) - expected(a, b))
    above_floor(a + change)
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

  defp above_floor(adjusted) do
    round(max(100, adjusted))
  end
end
