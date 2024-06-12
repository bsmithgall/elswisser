defmodule Elchesser.Square do
  alias Elchesser.{Piece, Game, Move, Board, Game}
  alias __MODULE__
  alias Elchesser.Square.Sees

  defstruct file: nil,
            rank: nil,
            loc: {},
            piece: nil,
            sees: %Sees{}

  @type t :: %Square{}

  def from({file, rank}), do: from(file, rank, nil)
  def from(%Move{to: {file, rank}}), do: from(file, rank, nil)
  def from(file, rank), do: from(file, rank, nil)

  @spec from(number(), number(), Piece.t?()) :: t()
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
      loc: {file, rank},
      piece: piece,
      sees: Map.merge(sees, %{all: Map.values(sees) |> List.flatten() |> Enum.into(MapSet.new())})
    }
  end

  def valid?({file, rank}), do: file in Elchesser.files() && rank in Elchesser.ranks()

  @spec empty?(Elchesser.Square.t()) :: boolean()
  def empty?(%Square{piece: nil}), do: true
  def empty?(%Square{}), do: false

  @spec eq?(Elchesser.Square.t(), nil | {number(), number()} | Elchesser.Square.t()) :: boolean()
  def eq?(%Square{} = l, %Square{} = r), do: {l.file, l.rank} == {r.file, r.rank}
  def eq?(%Square{} = l, {file, rank}), do: l.file == file && l.rank == rank
  def eq?(%Square{}, nil), do: false

  def white?(%Square{piece: piece}), do: Piece.white?(piece)
  def black?(%Square{piece: piece}), do: Piece.black?(piece)

  def color(%Square{} = square) do
    cond do
      white?(square) -> :w
      black?(square) -> :b
      true -> nil
    end
  end

  @spec legal_moves(Square.t() | {number(), number()}, Game.t()) :: [Move.t()]
  def legal_moves(%Square{piece: nil}, _), do: []

  def legal_moves(%Square{piece: piece} = square, %Game{} = game) do
    if Piece.color_match?(piece, game.active),
      do:
        Piece.module(piece).moves(square, game)
        |> Enum.reject(fn %Move{} = move ->
          {:ok, {_, g}} = Board.raw_move(game, move)
          Game.Check.check?(g, color(square))
        end),
      else: []
  end

  def legal_moves(loc, %Game{} = game), do: Game.get_square(game, loc) |> legal_moves(game)

  @spec legal_locs(Square.t() | {number(), number()}, Game.t()) :: [{number(), number()}]
  def legal_locs(square, %Game{} = game) do
    legal_moves(square, game) |> Enum.map(& &1.to)
  end

  def attacks(%Square{piece: nil}, _), do: []

  def attacks(%Square{piece: piece} = square, %Game{} = game) do
    Piece.module(piece).attacks(square, game)
  end

  def piece_display(%Square{} = square), do: Elchesser.Piece.display(square.piece)

  def rf(%Square{file: file, rank: rank}), do: {file, rank}
  def rf_string(%Square{file: file, rank: rank}), do: <<file, rank + 48>>

  @spec move_range(%Square{}, %Game{}, Square.Sees.t()) :: [Move.t()]
  def move_range(%Square{} = square, %Game{} = game, direction) do
    Kernel.get_in(square.sees, [Access.key!(direction)])
    |> Enum.reduce_while([], fn {file, rank}, acc ->
      s = Game.get_square(game, {file, rank})

      case Piece.friendly?(square.piece, s.piece) do
        true -> {:halt, acc}
        false -> {:halt, [Move.from(square, {s.file, s.rank}, capture: true) | acc]}
        nil -> {:cont, [Move.from(square, {s.file, s.rank}) | acc]}
      end
    end)
    |> Enum.reverse()
  end

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
