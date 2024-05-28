defmodule Elchesser.Piece.King do
  alias Elchesser.{Square, Game, Move, Piece, Board}

  @behaviour Piece

  @impl true
  def moves(%Square{piece: :K} = square, game) do
    moves(square, game, Board.black_attacks(game) |> Enum.into(MapSet.new()))
  end

  def moves(%Square{piece: :k} = square, game) do
    moves(square, game, Board.white_attacks(game) |> Enum.into(MapSet.new()))
  end

  @impl true
  def attacks(%Square{} = square, %Game{} = game) do
    attacks(square)
    |> Enum.reduce([], fn {file, rank}, acc ->
      s = Map.get(game.board, {file, rank})

      case Piece.friendly?(square.piece, s.piece) do
        true -> acc
        false -> [Move.from(square, {s.file, s.rank}, capture: true) | acc]
        nil -> [Move.from(square, {s.file, s.rank}) | acc]
      end
    end)
  end

  defp moves(%Square{} = square, %Game{} = game, %MapSet{} = attacks) do
    attacks(square, game)
    |> Enum.concat(maybe_castle_kingside(square, game, attacks))
    |> Enum.concat(maybe_castle_queenside(square, game, attacks))
    |> Enum.reject(&MapSet.member?(attacks, &1.to))
  end

  defp attacks(%Square{file: file, rank: rank}) do
    for(f <- -1..1, r <- -1..1, not (f == 0 and r == 0), do: {file + f, rank + r})
    |> Enum.filter(&Square.valid?/1)
  end

  defp maybe_castle_kingside(%Square{piece: piece}, %Game{castling: c}, _)
       when not is_map_key(c.map, piece),
       do: []

  defp maybe_castle_kingside(%Square{piece: :K} = square, %Game{} = game, attacks) do
    through_squares = [{?f, 1}, {?g, 1}] |> Enum.map(&Game.get_square(game, &1))

    if can_castle?(through_squares, attacks),
      do: [Move.from(square, {?g, 1}, castle: true)],
      else: []
  end

  defp maybe_castle_kingside(%Square{piece: :k} = square, %Game{} = game, attacks) do
    through_squares = [{?f, 8}, {?g, 8}] |> Enum.map(&Game.get_square(game, &1))

    if can_castle?(through_squares, attacks),
      do: [Move.from(square, {?g, 8}, castle: true)],
      else: []
  end

  defp maybe_castle_queenside(%Square{piece: :K}, %Game{castling: c}, _)
       when not is_map_key(c.map, :Q),
       do: []

  defp maybe_castle_queenside(%Square{piece: :k}, %Game{castling: c}, _)
       when not is_map_key(c.map, :q),
       do: []

  defp maybe_castle_queenside(%Square{piece: :K} = square, %Game{} = game, attacks) do
    empty_squares = [{?d, 1}, {?c, 1}, {?b, 1}] |> Enum.map(&Game.get_square(game, &1))
    attack_squares = [{?d, 1}, {?c, 1}] |> Enum.map(&Game.get_square(game, &1))

    if can_castle?(empty_squares, attack_squares, attacks),
      do: [Move.from(square, {?c, 1}, castle: true)],
      else: []
  end

  defp maybe_castle_queenside(%Square{piece: :k} = square, %Game{} = game, attacks) do
    empty_squares = [{?d, 8}, {?c, 8}, {?b, 8}] |> Enum.map(&Game.get_square(game, &1))
    attack_squares = [{?d, 8}, {?c, 8}] |> Enum.map(&Game.get_square(game, &1))

    if can_castle?(empty_squares, attack_squares, attacks),
      do: [Move.from(square, {?c, 8}, castle: true)],
      else: []
  end

  @spec can_castle?([Square.t()], MapSet.t()) :: boolean()
  defp can_castle?(through_squares, attacks),
    do: can_castle?(through_squares, through_squares, attacks)

  @spec can_castle?([Square.t()], [Square.t()], MapSet.t()) :: boolean()
  defp can_castle?(empty_through, attack_through, attacks) do
    empty? = Enum.all?(empty_through, &Square.empty?/1)

    attacked? =
      attacks |> Enum.map(&Square.from/1) |> Enum.any?(&(&1 in attack_through))

    empty? and not attacked?
  end
end
