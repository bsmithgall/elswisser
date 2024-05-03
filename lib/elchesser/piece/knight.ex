defmodule Elchesser.Piece.Knight do
  alias Elchesser.{Square, Game, Piece, Move}

  @behaviour Piece

  @impl true
  def moves(%Square{} = square, %Game{} = game) do
    Enum.reduce(square.sees.knight, [], fn {file, rank}, acc ->
      s = Map.get(game.board, {file, rank})

      case Piece.friendly?(square.piece, s.piece) do
        true -> acc
        false -> [Move.from(square, {s.file, s.rank}, capture: true) | acc]
        nil -> [Move.from(square, {s.file, s.rank}) | acc]
      end
    end)
  end

  @impl true
  def attacks(square, game), do: moves(square, game)
end
