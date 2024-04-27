defmodule Elchesser.Square.Sees do
  @type t() ::
          :up | :down | :left | :right | :up_right | :up_left | :down_left | :down_right | :knight

  defstruct up: [],
            down: [],
            left: [],
            right: [],
            up_right: [],
            up_left: [],
            down_left: [],
            down_right: [],
            knight: [],
            all: MapSet.new()
end
