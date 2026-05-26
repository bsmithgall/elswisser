defmodule Elchesser.Game.Castling do
  alias Elchesser.{Game, Move}

  @spec set_castling_rights(Game.t(), Move.t()) :: Game.t()

  # king moves

  def set_castling_rights(%Game{castling: castling} = game, %Move{piece: :K}) do
    %Game{game | castling: MapSet.delete(castling, :K) |> MapSet.delete(:Q)}
  end

  def set_castling_rights(%Game{castling: castling} = game, %Move{piece: :k}) do
    %Game{game | castling: MapSet.delete(castling, :k) |> MapSet.delete(:q)}
  end

  # rook move away

  def set_castling_rights(%Game{castling: castling} = game, %Move{from: {?h, 1}, piece: :R}) do
    %Game{game | castling: MapSet.delete(castling, :K)}
  end

  def set_castling_rights(%Game{castling: castling} = game, %Move{from: {?a, 1}, piece: :R}) do
    %Game{game | castling: MapSet.delete(castling, :Q)}
  end

  def set_castling_rights(%Game{castling: castling} = game, %Move{from: {?h, 8}, piece: :r}) do
    %Game{game | castling: MapSet.delete(castling, :k)}
  end

  def set_castling_rights(%Game{castling: castling} = game, %Move{from: {?a, 8}, piece: :r}) do
    %Game{game | castling: MapSet.delete(castling, :q)}
  end

  # something moving into a starting rook square
  #
  def set_castling_rights(%Game{castling: castling} = game, %Move{to: {?h, 1}}) do
    %Game{game | castling: MapSet.delete(castling, :K)}
  end

  def set_castling_rights(%Game{castling: castling} = game, %Move{to: {?a, 1}}) do
    %Game{game | castling: MapSet.delete(castling, :Q)}
  end

  def set_castling_rights(%Game{castling: castling} = game, %Move{to: {?h, 8}}) do
    %Game{game | castling: MapSet.delete(castling, :k)}
  end

  def set_castling_rights(%Game{castling: castling} = game, %Move{to: {?a, 8}}) do
    %Game{game | castling: MapSet.delete(castling, :q)}
  end

  def set_castling_rights(game, _), do: game
end
