defmodule Elswisser.Pairings.Seed do
  def seed(items) when is_list(items) do
    generate_seeds(length(items))
    |> Enum.map(fn {l, r} ->
      {Enum.at(items, l - 1), Enum.at(items, r - 1)}
    end)
  end

  def generate_seeds(size) when is_number(size) do
    generate_seeds([], 1, 1, Math.log2(size))
  end

  def generate_seeds(_acc, seed, level, limit) when level == limit do
    level_sum = (:math.pow(2, level) + 1) |> round()
    [{seed, level_sum - seed}]
  end

  def generate_seeds(acc, seed, level, limit) when rem(seed, 2) == 1 do
    level_sum = (:math.pow(2, level) + 1) |> round()

    [
      generate_seeds(acc, level_sum - seed, level + 1, limit)
      | [generate_seeds(acc, seed, level + 1, limit) | acc]
    ]
    |> Enum.reverse()
    |> List.flatten()
  end

  def generate_seeds(acc, seed, level, limit) do
    level_sum = (:math.pow(2, level) + 1) |> round()

    [
      generate_seeds(acc, seed, level + 1, limit)
      | [generate_seeds(acc, level_sum - seed, level + 1, limit) | acc]
    ]
    |> Enum.reverse()
    |> List.flatten()
  end
end
