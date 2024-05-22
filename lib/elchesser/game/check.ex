defmodule Elchesser.Game.Check do
  alias Elchesser.{Game, Board}

  def check?(%Game{active: active} = game), do: check?(game, active)

  def opponent_in_check?(%Game{active: :w} = game), do: check?(game, :b)
  def opponent_in_check?(%Game{active: :b} = game), do: check?(game, :w)

  @spec check?(Elchesser.Game.t(), :b | :w) :: boolean()
  def check?(%Game{} = game, :w) do
    Board.find(game, :K) |> then(&Board.black_attacks_any?(game, &1))
  end

  def check?(%Game{} = game, :b) do
    Board.find(game, :k) |> then(&Board.white_attacks_any?(game, &1))
  end
end
