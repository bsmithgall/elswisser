defmodule Elchesser.Moves do
  alias Elchesser.Game

  def generate_moves(%Game{} = game) do
    for file <- Elchesser.Game.files(), rank <- Elchesser.Game.ranks(), reduce: %{} do
      acc ->
        Map.put(acc, {file, rank}, generate_moves(file, rank, Map.get(game.board, {file, rank})))
    end
  end

  defp generate_moves(file, rank, :R) do
  end

  defp generate_moves(_, _, _), do: []
end
