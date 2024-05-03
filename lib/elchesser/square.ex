defmodule Elchesser.Square do
  alias Elchesser.{Piece, Game, Move}
  alias __MODULE__
  alias Elchesser.Square.Sees

  defstruct file: nil,
            rank: nil,
            piece: nil,
            sees: %Sees{}

  @type t :: %Square{}

  def from({file, rank}), do: from(file, rank, nil)
  def from(%Move{file: file, rank: rank}), do: from(file, rank, nil)
  def from(file, rank), do: from(file, rank, nil)

  @spec from(number(), number(), Piece.t() | nil) :: t()
  def from(file, rank, piece) do
    sees = %Sees{
      up: up(file, rank),
      down: down(file, rank),
      left: left(file, rank),
      right: right(file, rank),
      up_right: up_right(file, rank),
      up_left: up_left(file, rank),
      down_right: down_right(file, rank),
      down_left: down_left(file, rank),
      knight: knight_moves(file, rank)
    }

    %Square{
      file: file,
      rank: rank,
      piece: piece,
      sees: Map.merge(sees, %{all: Map.values(sees) |> List.flatten() |> Enum.into(MapSet.new())})
    }
  end

  def valid?({file, rank}), do: file in Elchesser.files() && rank in Elchesser.ranks()

  def empty?(%Square{piece: nil}), do: true
  def empty?(%Square{}), do: false

  def eq?(%Square{} = l, %Square{} = r), do: l == r
  def eq?(%Square{} = l, {file, rank}), do: l.file == file && l.rank == rank
  def eq?(%Square{}, nil), do: false

  def white?(%Square{piece: piece}), do: Piece.white?(piece)
  def black?(%Square{piece: piece}), do: Piece.black?(piece)

  def attacks(%Square{piece: nil}, _), do: []

  def attacks(%Square{piece: piece} = square, %Game{} = game) do
    Piece.module(piece).attacks(square, game)
  end

  def piece_display(%Square{} = square), do: Elchesser.Piece.display(square.piece)

  defp up(file, rank), do: for(r <- Elchesser.ranks(), r > rank, do: {file, r})

  defp down(file, rank),
    do: for(r <- Elchesser.ranks() |> Enum.reverse(), r < rank, do: {file, r})

  defp left(file, rank),
    do: for(f <- Elchesser.files() |> Enum.reverse(), f < file, do: {f, rank})

  defp right(file, rank), do: for(f <- Elchesser.files(), f > file, do: {f, rank})

  defp up_right(file, rank) do
    1..8
    |> Enum.reduce_while([], fn idx, acc ->
      cond do
        file + idx > ?h -> {:halt, acc}
        rank + idx > 8 -> {:halt, acc}
        true -> {:cont, [{file + idx, rank + idx} | acc]}
      end
    end)
    |> Enum.reverse()
  end

  defp up_left(file, rank) do
    1..8
    |> Enum.reduce_while([], fn idx, acc ->
      cond do
        file - idx < ?a -> {:halt, acc}
        rank + idx > 8 -> {:halt, acc}
        true -> {:cont, [{file - idx, rank + idx} | acc]}
      end
    end)
    |> Enum.reverse()
  end

  defp down_left(file, rank) do
    1..8
    |> Enum.reduce_while([], fn idx, acc ->
      cond do
        file - idx < ?a -> {:halt, acc}
        rank - idx < 1 -> {:halt, acc}
        true -> {:cont, [{file - idx, rank - idx} | acc]}
      end
    end)
    |> Enum.reverse()
  end

  defp down_right(file, rank) do
    1..8
    |> Enum.reduce_while([], fn idx, acc ->
      cond do
        file + idx > ?h -> {:halt, acc}
        rank - idx < 1 -> {:halt, acc}
        true -> {:cont, [{file + idx, rank - idx} | acc]}
      end
    end)
    |> Enum.reverse()
  end

  defp knight_moves(file, rank) do
    [{2, 1}, {-2, 1}, {2, -1}, {-2, -1}, {1, 2}, {-1, 2}, {1, -2}, {-1, -2}]
    |> Enum.map(fn {f, r} -> {file + f, rank + r} end)
    |> Enum.filter(&Square.valid?/1)
  end
end
