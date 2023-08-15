defmodule Elswisser.Pairings.PairWeight do
  alias Elswisser.Pairings.Pairing

  def score(%Pairing{} = p1, %Pairing{} = p2) do
    half_differential(p1, p2)
  end

  def score(%Pairing{} = p1, %Pairing{} = p2, max_score) when is_nil(max_score) do
    score(p1, p2)
  end

  def score(%Pairing{} = p1, %Pairing{} = p2, max_score) when max_score == 0 do
    score(p1, p2)
  end

  def score(%Pairing{} = p1, %Pairing{} = p2, max_score) when max_score > 0 do
    yet_to_meet(p1, p2) * max_score +
      (max_score * 16 - score_difference(p1, p2) * 16) +
      half_differential(p1, p2) + due_different_colors(p1, p2)
  end

  # 27A1. A player may not play the same opponent more than once in a tournament
  defp yet_to_meet(%Pairing{} = p1, %Pairing{} = p2) do
    if Enum.all?(p1.score.opponents, fn o -> o != p2.player_id end), do: 32, else: 0
  end

  # 27A2. Players with equal scores are paired whenever possible
  defp score_difference(%Pairing{} = p1, %Pairing{} = p2) do
    abs(p1.score.score - p2.score.score)
  end

  # 27A3. Within a score group, i.e., all players who have the same score, the
  # upper half by ranking (28A) is paired against the lower half.
  defp half_differential(%Pairing{} = p1, %Pairing{} = p2) do
    if same_score(p1, p2) && different_halves(p1, p2),
      do: 4 / (abs(p1.half_idx - p2.half_idx) + 1),
      else: 0
  end

  # 27A4. Players receive each color the same number of times, whenever practical,
  # and are not assigned the same color more than twice in a row.
  def due_different_colors(%Pairing{} = p1, %Pairing{} = p2) do
    if p1.score.lastwhite != p2.score.lastwhite, do: 2, else: 0
  end

  defp different_halves(%Pairing{} = p1, %Pairing{} = p2) do
    p1.upperhalf != p2.upperhalf
  end

  defp same_score(%Pairing{} = p1, %Pairing{} = p2) do
    p1.score.score == p2.score.score
  end
end
