defmodule Elchesser.Square.Sees do
  @type t() :: :up | :down | :left | :right | :up_right | :up_left | :down_left | :down_right

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
