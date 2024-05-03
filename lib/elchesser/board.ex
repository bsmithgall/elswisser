defmodule Elchesser.Board do
  alias Elchesser.{Game, Square}

  @spec white_attacks(Game.t()) :: [Square.t()]
  def white_attacks(%Game{} = game) do
    white_occupied(game)
    |> Enum.map(&Square.attacks(&1, game))
    |> List.flatten()
    |> Enum.uniq()
  end

  @spec black_attacks(Game.t()) :: [Square.t()]
  def black_attacks(%Game{} = game) do
    black_occupied(game)
    |> Enum.map(&Square.attacks(&1, game))
    |> List.flatten()
    |> Enum.uniq()
  end

  @spec white_attacks_any?(Game.t(), [Square.t()]) :: boolean()
  def white_attacks_any?(%Game{} = game, squares) do
    white_attacks(game) |> Enum.any?(fn square -> square in squares end)
  end

  @spec black_attacks_any?(Game.t(), [Square.t()]) :: boolean()
  def black_attacks_any?(%Game{} = game, squares) do
    black_attacks(game) |> Enum.any?(fn square -> square in squares end)
  end

  def white_occupied(%Game{board: board}) do
    Map.filter(board, fn {_, square} -> Square.white?(square) end)
    |> Map.values()
  end

  def black_occupied(%Game{board: board}) do
    Map.filter(board, fn {_, square} -> Square.black?(square) end)
    |> Map.values()
  end
end
