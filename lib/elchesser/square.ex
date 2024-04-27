defmodule Elchesser.Square do
  alias __MODULE__
  alias Elchesser.Square.Sees

  defstruct file: nil,
            rank: nil,
            piece: nil,
            knight_moves: [],
            sees: %Sees{}

  @type t :: %Square{}

  @spec from(number(), number(), String.t() | nil) :: t()
  def from(file, rank, piece) do
    sees = %{
      up: up(file, rank),
      down: down(file, rank),
      left: left(file, rank),
      right: right(file, rank),
      up_right: up_right(file, rank),
      up_left: up_left(file, rank),
      down_right: down_right(file, rank),
      down_left: down_left(file, rank)
    }

    %Square{
      file: file,
      rank: rank,
      piece: piece,
      sees:
        Map.merge(sees, %{all: Map.values(sees) |> List.flatten() |> Enum.into(MapSet.new())}),
      knight_moves: knight_moves(file, rank)
    }
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

  defp knight_moves(_file, _rank), do: []
end
