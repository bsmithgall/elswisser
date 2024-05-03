defmodule Elchesser.Move do
  defstruct file: ?a, rank: 1, capture: false, promotion: false, castle: false

  @type t :: %__MODULE__{}

  alias Elchesser.{Game, Square, Piece}
  alias __MODULE__

  def from({file, rank}), do: %Move{file: file, rank: rank}

  @spec move_range(%Square{}, %Game{}, Square.Sees.t()) :: [t()]
  def move_range(%Square{} = square, %Game{} = game, direction) do
    get_in(square.sees, [Access.key!(direction)])
    |> Enum.reduce_while([], fn {file, rank}, acc ->
      s = Map.get(game.board, {file, rank})

      case Piece.friendly?(square.piece, s.piece) do
        true -> {:halt, acc}
        false -> {:halt, [%Move{file: s.file, rank: s.rank, capture: true} | acc]}
        nil -> {:cont, [%Move{file: s.file, rank: s.rank} | acc]}
      end
    end)
    |> Enum.reverse()
  end
end
