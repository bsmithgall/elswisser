defmodule Elchesser.Board.Attacks do
  alias Elchesser.Square.Sees
  alias Elchesser.{Game, Square, Board}

  @doc """
  Short-circuiting reverse check against things attacking a given square.
  Used to speed up `Check.check?/2` lookups. The third color argument
  should be the color _doing_ the attacking. So to check if the square
  is attacked by the white pieces, pass :w
  """
  @spec square_attacked_by?(Game.t(), Square.t(), :w | :b) :: boolean()
  def square_attacked_by?(%Game{} = game, %Square{} = square, color) do
    diagonal_attack?(game, square, color) or
      rank_file_attack?(game, square, color) or
      knight_attack?(game, square, color) or
      pawn_attack?(game, square, color)
  end

  defp diagonal_attack?(%Game{} = game, %Square{} = square, :w) do
    Square.diagonal()
    |> Enum.any?(fn dir ->
      Sees.first_piece_seen(square.sees, game, dir) in [:Q, :B]
    end)
  end

  defp diagonal_attack?(%Game{} = game, %Square{} = square, :b) do
    Square.diagonal()
    |> Enum.any?(fn dir ->
      Sees.first_piece_seen(square.sees, game, dir) in [:q, :b]
    end)
  end

  defp rank_file_attack?(%Game{} = game, %Square{} = square, :w) do
    Square.rank_file()
    |> Enum.any?(fn dir -> Sees.first_piece_seen(square.sees, game, dir) in [:Q, :R] end)
  end

  defp rank_file_attack?(%Game{} = game, %Square{} = square, :b) do
    Square.rank_file()
    |> Enum.any?(fn dir -> Sees.first_piece_seen(square.sees, game, dir) in [:q, :r] end)
  end

  defp knight_attack?(%Game{} = game, %Square{} = square, :w) do
    square.sees.knight |> Enum.any?(fn sq -> Board.get_square(game, sq).piece == :N end)
  end

  defp knight_attack?(%Game{} = game, %Square{} = square, :b) do
    square.sees.knight |> Enum.any?(fn sq -> Board.get_square(game, sq).piece == :n end)
  end

  defp pawn_attack?(%Game{} = game, %Square{} = square, :w) do
    [{square.file - 1, square.rank - 1}, {square.file + 1, square.rank - 1}]
    |> Enum.any?(fn loc ->
      Square.valid?(loc) and Board.get_square(game, loc).piece == :P
    end)
  end

  defp pawn_attack?(%Game{} = game, %Square{} = square, :b) do
    [{square.file - 1, square.rank + 1}, {square.file + 1, square.rank + 1}]
    |> Enum.any?(fn loc ->
      Square.valid?(loc) and Board.get_square(game, loc).piece == :p
    end)
  end
end
