defmodule Elchesser.Piece.Rook do
  alias Elchesser.{Square, Game, Move}

  @behaviour Elchesser.Piece

  @impl true
  def moves(%Square{} = square, %Game{} = game) do
    for d <- [:up, :down, :left, :right], reduce: [] do
      acc -> [Move.move_range(square, game, d) | acc]
    end
    |> List.flatten()
  end

  @impl true
  def attacks(square, game), do: moves(square, game)
end
