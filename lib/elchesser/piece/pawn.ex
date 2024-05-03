defmodule Elchesser.Piece.Pawn do
  alias Elchesser.{Square, Game, Move, Piece}

  @behaviour Piece

  @impl true
  def moves(%Square{piece: :P, rank: 2, file: file} = square, %Game{} = game),
    do: moves(square, game, [{file, 3}, {file, 4}], false)

  def moves(%Square{piece: :P, rank: rank, file: file} = square, %Game{} = game),
    do: moves(square, game, [{file, rank + 1}], rank + 1 == 8)

  def moves(%Square{piece: :p, rank: 7, file: file} = square, %Game{} = game),
    do: moves(square, game, [{file, 6}, {file, 5}], false)

  def moves(%Square{piece: :p, rank: 2, file: file} = square, %Game{} = game),
    do: moves(square, game, [{file, 1}], true)

  def moves(%Square{piece: :p, rank: rank, file: file} = square, %Game{} = game),
    do: moves(square, game, [{file, rank - 1}], false)

  @impl true
  def attacks(%Square{} = square, _), do: attacks(square) |> Enum.map(&Move.from/1)

  defp moves(square, game, candidates, promotion) do
    m =
      candidates
      |> Enum.filter(fn candidate -> Game.get_square(game, candidate) |> Square.empty?() end)
      |> Enum.map(fn {file, rank} -> %Move{file: file, rank: rank, promotion: promotion} end)

    a =
      attacks(square)
      |> Enum.filter(fn s ->
        Game.get_square(game, s)
        |> then(&(Piece.enemy?(square.piece, &1.piece) || en_passant?(&1, game)))
      end)
      |> Enum.map(fn {file, rank} ->
        %Move{file: file, rank: rank, capture: true, promotion: promotion}
      end)

    Enum.concat(m, a)
  end

  defp attacks(%Square{piece: :P, rank: rank, file: file}) do
    [{file + 1, rank + 1}, {file - 1, rank + 1}]
    |> Enum.filter(&Square.valid?/1)
  end

  defp attacks(%Square{piece: :p, file: file, rank: rank}) do
    [{file + 1, rank - 1}, {file - 1, rank - 1}]
    |> Enum.filter(&Square.valid?/1)
  end

  defp en_passant?(%Square{} = square, %Game{} = game) do
    Square.empty?(square) && Square.eq?(square, game.en_passant)
  end
end
