defmodule Elchesser.Piece.Bishop do
  alias Elchesser.{Square, Game, Piece}

  @behaviour Piece

  @impl true
  def moves(%Square{} = square, %Game{} = game) do
    for d <- [:up_right, :up_left, :down_left, :down_right], reduce: [] do
      acc -> [Square.move_range(square, game, d) | acc]
    end
    |> List.flatten()
  end

  @impl true
  def attacks(square, game), do: moves(square, game)
end
