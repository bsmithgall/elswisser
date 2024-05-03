defmodule Elchesser.Piece.KnightTest do
  use ExUnit.Case, async: true

  alias Elchesser.{Game, Move}
  alias Elchesser.Piece.Knight

  import TestHelper

  test "only knight on the board" do
    game = Elchesser.Fen.parse("8/8/8/3n4/8/8/8/8 w KQkq - 0 1")
    square = Game.get_square(game, {?d, 5})

    assert Knight.moves(square, game) == Knight.attacks(square, game)

    assert_list_eq_any_order(Knight.moves(square, game), [
      Move.from(square, {?c, 7}),
      Move.from(square, {?c, 3}),
      Move.from(square, {?b, 6}),
      Move.from(square, {?b, 4}),
      Move.from(square, {?e, 7}),
      Move.from(square, {?e, 3}),
      Move.from(square, {?f, 6}),
      Move.from(square, {?f, 4})
    ])
  end

  test "knight on the edge of the board" do
    #   ┌───┬───┬───┬───┬───┬───┬───┬───┐
    # 8 │ ♘ │   │   │   │   │   │   │   │
    #   ├───┼───┼───┼───┼───┼───┼───┼───┤
    # 7 │   │   │   │   │   │   │   │   │
    #   ├───┼───┼───┼───┼───┼───┼───┼───┤
    # 6 │   │   │   │   │   │   │   │   │
    #   ├───┼───┼───┼───┼───┼───┼───┼───┤
    # 5 │   │   │   │   │   │   │   │   │
    #   ├───┼───┼───┼───┼───┼───┼───┼───┤
    # 4 │   │   │   │   │   │   │   │   │
    #   ├───┼───┼───┼───┼───┼───┼───┼───┤
    # 3 │   │   │   │   │   │   │   │   │
    #   ├───┼───┼───┼───┼───┼───┼───┼───┤
    # 2 │   │   │   │   │   │   │   │   │
    #   ├───┼───┼───┼───┼───┼───┼───┼───┤
    # 1 │   │   │   │   │   │   │   │   │
    #   └───┴───┴───┴───┴───┴───┴───┴───┘
    #     a   b   c   d   e   f   g   h
    game = Elchesser.Fen.parse("N7/8/8/8/8/8/8/8 w KQkq - 0 1")
    square = Game.get_square(game, {?a, 8})

    assert Knight.moves(square, game) == Knight.attacks(square, game)

    assert_list_eq_any_order(Knight.moves(square, game), [
      Move.from(square, {?c, 7}),
      Move.from(square, {?b, 6})
    ])
  end

  test "with interposing pieces" do
    #   ┌───┬───┬───┬───┬───┬───┬───┬───┐
    # 8 │ ♘ │   │   │   │   │   │   │   │
    #   ├───┼───┼───┼───┼───┼───┼───┼───┤
    # 7 │   │ ♗ │ ♗ │   │   │   │   │   │
    #   ├───┼───┼───┼───┼───┼───┼───┼───┤
    # 6 │ ♟ │ ♟ │ ♟ │ ♟ │   │   │   │   │
    #   ├───┼───┼───┼───┼───┼───┼───┼───┤
    # 5 │   │   │   │   │   │   │   │   │
    #   ├───┼───┼───┼───┼───┼───┼───┼───┤
    # 4 │   │   │   │   │   │   │   │   │
    #   ├───┼───┼───┼───┼───┼───┼───┼───┤
    # 3 │   │   │   │   │   │   │   │   │
    #   ├───┼───┼───┼───┼───┼───┼───┼───┤
    # 2 │   │   │   │   │   │   │   │   │
    #   ├───┼───┼───┼───┼───┼───┼───┼───┤
    # 1 │   │   │   │   │   │   │   │   │
    #   └───┴───┴───┴───┴───┴───┴───┴───┘
    #     a   b   c   d   e   f   g   h
    game = Elchesser.Fen.parse("N7/1BB5/pppp4/8/8/8/8/8 w KQkq - 0 1")
    square = Game.get_square(game, {?a, 8})

    assert Knight.attacks(square, game) == Knight.moves(square, game)

    assert Knight.moves(square, game) == [Move.from(square, {?b, 6}, capture: true)]
  end
end
