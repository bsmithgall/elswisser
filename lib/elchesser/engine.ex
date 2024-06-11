defmodule Elchesser.Engine do
  alias Elchesser.{Game, Move}

  @type t :: module()

  @callback move(Game.t()) :: Move.t()
end
