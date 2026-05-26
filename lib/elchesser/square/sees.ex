defmodule Elchesser.Square.Sees do
  alias Elchesser.{Game, Board, Square}
  alias __MODULE__

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

  def first_piece_seen(%Sees{} = sees, %Game{} = game, direction) do
    Map.get(sees, direction, {-1, -1})
    |> Enum.find_value(fn loc ->
      square = Board.get_square(game.board, loc)

      case Square.empty?(square) do
        true -> nil
        false -> square.piece
      end
    end)
  end
end
