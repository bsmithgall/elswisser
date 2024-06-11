defmodule Elchesser.Engine.Random do
  @moduledoc """
  An engine that picks a move at random and plays it
  """

  alias Elchesser.{Game, Engine}

  @behaviour Engine

  @impl true
  def move(game), do: Game.all_legal_moves(game) |> Enum.random()
end
