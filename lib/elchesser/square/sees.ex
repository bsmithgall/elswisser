defmodule Elchesser.Square.Sees do
  defstruct up: [],
            down: [],
            left: [],
            right: [],
            up_right: [],
            up_left: [],
            down_left: [],
            down_right: [],
            all: MapSet.new()
end
