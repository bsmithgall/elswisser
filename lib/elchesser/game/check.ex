defmodule Elchesser.Game.Check do
  alias Elchesser.{Game, Board}

  def opponent_checking(%Game{} = game) do
    in_check? = opponent_in_check?(game)
    any_moves? = any_legal_moves?(game)

    cond do
      in_check? and any_moves? -> :check
      in_check? and not any_moves? -> :checkmate
      not in_check? and not any_moves? -> :stalemate
      true -> nil
    end
  end

  def check?(%Game{active: active} = game), do: check?(game, active)

  def opponent_in_check?(%Game{active: :w} = game), do: check?(game, :b)
  def opponent_in_check?(%Game{active: :b} = game), do: check?(game, :w)

  @spec check?(Game.t(), :b | :w) :: boolean()
  def check?(%Game{} = game, :w) do
    Board.find(game, :K) |> then(&Board.black_attacks_any?(game, &1))
  end

  def check?(%Game{} = game, :b) do
    Board.find(game, :k) |> then(&Board.white_attacks_any?(game, &1))
  end

  defp any_legal_moves?(%Game{active: :w} = game) do
    Board.black_occupied(game)
    |> Enum.any?(&(length(Elchesser.Square.legal_moves(&1, %{game | active: :b})) > 0))
  end

  defp any_legal_moves?(%Game{active: :b} = game) do
    Board.white_occupied(game)
    |> Enum.any?(&(length(Elchesser.Square.legal_moves(&1, %{game | active: :w})) > 0))
  end
end
