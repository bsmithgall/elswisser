defmodule Elchesser.Engine.EagerBeaver do
  @moduledoc """
  Pick the best move without considering any followup
  """
  alias Elchesser.Piece
  alias Elchesser.Game

  use Elchesser.Engine

  @impl true
  def move(%Game{} = game) do
    game
    |> Game.all_legal_moves()
    |> Enum.max_by(fn move ->
      {:ok, try} = Game.make_move(game, move)
      -negamax(try, 1)
    end)
  end

  defp negamax(game, 0), do: evaluate(game)

  defp negamax(game, depth) do
    game
    |> Game.all_legal_moves()
    |> Enum.map(fn move ->
      {:ok, try} = Game.make_move(game, move)
      -negamax(try, depth - 1)
    end)
    |> Enum.max()
  end

  @impl true
  def evaluate(%Game{active: :w} = game) do
    Map.values(game.board) |> Enum.sum_by(&material_value(&1.piece))
  end

  def evaluate(%Game{active: :b} = game) do
    Map.values(game.board) |> Enum.sum_by(&material_value(&1.piece)) |> then(fn e -> e * -1 end)
  end

  @spec material_value(Piece.t()) :: number()
  defp material_value(:p), do: -100 + jitter()
  defp material_value(:n), do: -290 + jitter()
  defp material_value(:b), do: -330 + jitter()
  defp material_value(:r), do: -500 + jitter()
  defp material_value(:q), do: -900 + jitter()
  defp material_value(:k), do: -10_000 + jitter()

  defp material_value(:P), do: 100 + jitter()
  defp material_value(:N), do: 290 + jitter()
  defp material_value(:B), do: 330 + jitter()
  defp material_value(:R), do: 500 + jitter()
  defp material_value(:Q), do: 900 + jitter()
  defp material_value(:K), do: 10_000 + jitter()

  defp material_value(_), do: 0

  defp jitter(), do: (:rand.uniform() - 0.5) * 0.1
end
