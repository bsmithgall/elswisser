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
  def attacks(%Square{} = square, _), do: attacks(square) |> Enum.map(&Move.from(square, &1))

  @spec moves(Square.t(), Game.t(), [{integer(), integer()}], boolean()) :: [Square.t()]
  defp moves(square, game, candidates, promotion) do
    m =
      valid_candidates(game, candidates)
      |> Enum.map(fn {file, rank} ->
        Move.from(square, {file, rank}, promotion: promote(promotion, square.piece))
      end)

    a =
      attacks(square)
      |> Enum.filter(fn s ->
        sq = Game.get_square(game, s)
        Piece.enemy?(square.piece, sq.piece) || en_passant?(sq, game)
      end)
      |> Enum.map(fn s ->
        sq = Game.get_square(game, s)
        ep? = en_passant?(sq, game)

        capture =
          cond do
            ep? and square.piece == :P -> :p
            ep? and square.piece == :p -> :P
            true -> sq.piece
          end

        Move.from(square, s, capture: capture, promotion: promote(promotion, square.piece))
      end)

    Enum.concat(m, a)
  end

  defp valid_candidates(%Game{} = game, [first, second] = c) when length(c) == 2 do
    first_empty? = Game.get_square(game, first) |> Square.empty?()
    second_empty? = Game.get_square(game, second) |> Square.empty?()

    cond do
      not first_empty? -> []
      not second_empty? -> [first]
      true -> [first, second]
    end
  end

  defp valid_candidates(%Game{} = game, [candidate] = c) when length(c) == 1 do
    if Game.get_square(game, candidate) |> Square.empty?(), do: [candidate], else: []
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

  defp promote(false, _), do: nil
  defp promote(true, :p), do: :q
  defp promote(true, :P), do: :Q
end
