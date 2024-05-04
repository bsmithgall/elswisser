defmodule Elchesser.Game.Check do
  alias Elchesser.{Game, Board}

  def check?(%Game{} = game, :w) do
    Board.find(game, :K) |> then(&Board.black_attacks_any?(game, &1))
  end

  def check?(%Game{} = game, :b) do
    Board.find(game, :k) |> then(&Board.white_attacks_any?(game, &1))
  end
end
