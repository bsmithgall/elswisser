defmodule Elchesser.Piece.King do
  alias Elchesser.{Square, Game, Move, Piece, Board}

  @behaviour Piece

  @impl true
  def moves(%Square{piece: :K} = square, game) do
    black_attacks = Board.black_attacks(game)

    all =
      attacks(square, game)
      |> Enum.concat(maybe_castle_kingside(square, game, black_attacks))
      |> Enum.concat(maybe_castle_queenside(square, game, black_attacks))

    all -- black_attacks
  end

  def moves(%Square{piece: :k} = square, game) do
    white_attacks = Board.white_attacks(game)

    all =
      attacks(square, game)
      |> Enum.concat(maybe_castle_kingside(square, game, white_attacks))
      |> Enum.concat(maybe_castle_queenside(square, game, white_attacks))

    all -- white_attacks
  end

  @impl true
  def attacks(%Square{} = square, %Game{} = game) do
    attacks(square)
    |> Enum.reduce([], fn {file, rank}, acc ->
      s = Map.get(game.board, {file, rank})

      case Piece.friendly?(square.piece, s.piece) do
        true -> acc
        false -> [%Move{file: s.file, rank: s.rank, capture: true} | acc]
        nil -> [Move.from({s.file, s.rank}) | acc]
      end
    end)
  end

  defp attacks(%Square{file: file, rank: rank}) do
    for(f <- -1..1, r <- -1..1, not (f == 0 and r == 0), do: {file + f, rank + r})
    |> Enum.filter(&Square.valid?/1)
  end

  defp maybe_castle_kingside(%Square{piece: piece}, %Game{castling: c}, _)
       when not is_map_key(c.map, piece),
       do: []

  defp maybe_castle_kingside(%Square{piece: :K}, %Game{} = game, attacks) do
    through_squares = [{?f, 1}, {?g, 1}] |> Enum.map(&Game.get_square(game, &1))

    if can_castle?(through_squares, attacks),
      do: [%Move{file: ?g, rank: 1, castle: true}],
      else: []
  end

  defp maybe_castle_kingside(%Square{piece: :k}, %Game{} = game, attacks) do
    through_squares = [{?f, 8}, {?g, 8}] |> Enum.map(&Game.get_square(game, &1))

    if can_castle?(through_squares, attacks),
      do: [%Move{file: ?g, rank: 8, castle: true}],
      else: []
  end

  defp maybe_castle_queenside(%Square{piece: :K}, %Game{castling: c}, _)
       when not is_map_key(c.map, :Q),
       do: []

  defp maybe_castle_queenside(%Square{piece: :k}, %Game{castling: c}, _)
       when not is_map_key(c.map, :q),
       do: []

  defp maybe_castle_queenside(%Square{piece: :K}, %Game{} = game, attacks) do
    empty_squares = [{?d, 1}, {?c, 1}, {?b, 1}] |> Enum.map(&Game.get_square(game, &1))
    attack_squares = [{?d, 1}, {?c, 1}] |> Enum.map(&Game.get_square(game, &1))

    if can_castle?(empty_squares, attack_squares, attacks),
      do: [%Move{file: ?c, rank: 1, castle: true}],
      else: []
  end

  defp maybe_castle_queenside(%Square{piece: :k}, %Game{} = game, attacks) do
    empty_squares = [{?d, 8}, {?c, 8}, {?b, 8}] |> Enum.map(&Game.get_square(game, &1))
    attack_squares = [{?d, 8}, {?c, 8}] |> Enum.map(&Game.get_square(game, &1))

    if can_castle?(empty_squares, attack_squares, attacks),
      do: [%Move{file: ?c, rank: 8, castle: true}],
      else: []
  end

  @spec can_castle?([Square.t()], [Move.t()]) :: boolean()
  defp can_castle?(through_squares, attacks),
    do: can_castle?(through_squares, through_squares, attacks)

  @spec can_castle?([Square.t()], [Square.t()], [Move.t()]) :: boolean()
  defp can_castle?(empty_through, attack_through, attacks) do
    empty? = Enum.all?(empty_through, &Square.empty?/1)

    attacked? =
      attacks |> Enum.map(&Square.from/1) |> Enum.any?(&(&1 in attack_through))

    empty? and not attacked?
  end
end
