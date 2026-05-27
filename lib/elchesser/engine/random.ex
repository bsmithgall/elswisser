defmodule Elchesser.Engine.Random do
  @moduledoc """
  An engine that picks a move at random and plays it
  """

  alias Elchesser.Game

  use Elchesser.Engine

  @impl true
  def evaluate(_), do: 0

  @impl true
  def move(game), do: Game.all_legal_moves(game) |> Enum.random()
end
