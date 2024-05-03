defmodule Elchesser.Piece.QueenTest do
  use ExUnit.Case, async: true

  alias Elchesser.{Game, Move}
  alias Elchesser.Piece.Queen

  import TestHelper

  test "only queen on board" do
    game = Elchesser.Fen.parse("8/8/8/8/8/8/6Q1/8 w KQkq - 0 1")
    square = Game.get_square(game, {?g, 2})

    assert Queen.moves(square, game) == Queen.attacks(square, game)

    assert_list_eq_any_order(Queen.moves(square, game), [
      Move.from(square, {?h, 1}),
      Move.from(square, {?f, 1}),
      Move.from(square, {?f, 3}),
      Move.from(square, {?e, 4}),
      Move.from(square, {?d, 5}),
      Move.from(square, {?c, 6}),
      Move.from(square, {?b, 7}),
      Move.from(square, {?a, 8}),
      Move.from(square, {?h, 3}),
      Move.from(square, {?h, 2}),
      Move.from(square, {?a, 2}),
      Move.from(square, {?b, 2}),
      Move.from(square, {?c, 2}),
      Move.from(square, {?d, 2}),
      Move.from(square, {?e, 2}),
      Move.from(square, {?f, 2}),
      Move.from(square, {?g, 1}),
      Move.from(square, {?g, 3}),
      Move.from(square, {?g, 4}),
      Move.from(square, {?g, 5}),
      Move.from(square, {?g, 6}),
      Move.from(square, {?g, 7}),
      Move.from(square, {?g, 8})
    ])
  end

  test "with interposing pieces" do
    #   ┌───┬───┬───┬───┬───┬───┬───┬───┐
    # 8 │   │   │   │   │   │   │   │   │
    #   ├───┼───┼───┼───┼───┼───┼───┼───┤
    # 7 │   │ ♕ │   │   │   │   │   │   │
    #   ├───┼───┼───┼───┼───┼───┼───┼───┤
    # 6 │   │   │   │   │   │   │   │   │
    #   ├───┼───┼───┼───┼───┼───┼───┼───┤
    # 5 │   │   │   │   │   │   │   │   │
    #   ├───┼───┼───┼───┼───┼───┼───┼───┤
    # 4 │   │   │   │   │   │   │ ♖ │   │
    #   ├───┼───┼───┼───┼───┼───┼───┼───┤
    # 3 │   │   │   │   │   │   │   │   │
    #   ├───┼───┼───┼───┼───┼───┼───┼───┤
    # 2 │   │   │   │   │   │ ♝ │ ♛ │   │
    #   ├───┼───┼───┼───┼───┼───┼───┼───┤
    # 1 │   │   │   │   │   │   │   │   │
    #   └───┴───┴───┴───┴───┴───┴───┴───┘
    #     a   b   c   d   e   f   g   h
    game = Elchesser.Fen.parse("8/1Q6/8/8/6R1/8/5bq1/8 w KQkq - 0 1")
    square = Game.get_square(game, {?g, 2})

    assert Queen.moves(square, game) == Queen.attacks(square, game)

    assert_list_eq_any_order(Queen.moves(square, game), [
      Move.from(square, {?h, 2}),
      Move.from(square, {?h, 3}),
      Move.from(square, {?h, 1}),
      Move.from(square, {?g, 1}),
      Move.from(square, {?f, 1}),
      Move.from(square, {?g, 3}),
      Move.from(square, {?g, 4}, capture: true),
      Move.from(square, {?f, 3}),
      Move.from(square, {?e, 4}),
      Move.from(square, {?d, 5}),
      Move.from(square, {?c, 6}),
      Move.from(square, {?b, 7}, capture: true)
    ])
  end
end
