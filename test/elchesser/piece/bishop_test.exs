defmodule Elchesser.Piece.BishopTest do
  use ExUnit.Case, async: true

  alias Elchesser.{Game, Move}
  alias Elchesser.Piece.Bishop

  import TestHelper

  test "only bishop on board" do
    game = Elchesser.Fen.parse("8/8/5B2/8/8/8/8/8 w KQkq - 0 1")
    square = Game.get_square(game, {?f, 6})

    assert Bishop.moves(square, game) == Bishop.attacks(square, game)

    Bishop.moves(square, game)
    |> assert_list_eq_any_order([
      Move.from(square, {?g, 5}),
      Move.from(square, {?h, 4}),
      Move.from(square, {?e, 5}),
      Move.from(square, {?d, 4}),
      Move.from(square, {?c, 3}),
      Move.from(square, {?b, 2}),
      Move.from(square, {?a, 1}),
      Move.from(square, {?e, 7}),
      Move.from(square, {?d, 8}),
      Move.from(square, {?g, 7}),
      Move.from(square, {?h, 8})
    ])
  end

  test "with interposing pieces" do
    #   ┌───┬───┬───┬───┬───┬───┬───┬───┐
    # 8 │   │   │   │   │   │   │   │ ♖ │
    #   ├───┼───┼───┼───┼───┼───┼───┼───┤
    # 7 │   │   │   │   │   │   │   │   │
    #   ├───┼───┼───┼───┼───┼───┼───┼───┤
    # 6 │   │   │   │   │   │   │   │   │
    #   ├───┼───┼───┼───┼───┼───┼───┼───┤
    # 5 │   │   │   │   │   │   │   │   │
    #   ├───┼───┼───┼───┼───┼───┼───┼───┤
    # 4 │   │   │   │   │   │   │   │   │
    #   ├───┼───┼───┼───┼───┼───┼───┼───┤
    # 3 │ ♞ │   │   │   │   │   │   │   │
    #   ├───┼───┼───┼───┼───┼───┼───┼───┤
    # 2 │   │ ♝ │   │   │   │   │   │   │
    #   ├───┼───┼───┼───┼───┼───┼───┼───┤
    # 1 │   │   │   │   │   │   │   │   │
    #   └───┴───┴───┴───┴───┴───┴───┴───┘
    #     a   b   c   d   e   f   g   h
    game = Elchesser.Fen.parse("8/6R1/8/8/8/n7/1b6/8 w KQkq - 0 1")
    square = Game.get_square(game, {?b, 2})

    assert Bishop.moves(square, game) == Bishop.attacks(square, game)

    Bishop.moves(square, game)
    |> assert_list_eq_any_order([
      Move.from(square, {?c, 1}),
      Move.from(square, {?a, 1}),
      Move.from(square, {?c, 3}),
      Move.from(square, {?d, 4}),
      Move.from(square, {?e, 5}),
      Move.from(square, {?f, 6}),
      Move.from(square, {?g, 7}, capture: true)
    ])
  end
end
