defmodule Elchesser.Piece.RookTest do
  use ExUnit.Case, async: true

  alias Elchesser.{Game, Move}
  alias Elchesser.Piece.Rook

  import TestHelper

  test "only rook on board" do
    game = Elchesser.Fen.parse("8/8/8/8/4R3/8/8/8 w KQkq - 0 1")
    square = Game.get_square(game, {?e, 4})

    assert Rook.moves(square, game) == Rook.attacks(square, game)

    Rook.moves(square, game)
    |> assert_list_eq_any_order([
      Move.from(square, {?f, 4}),
      Move.from(square, {?g, 4}),
      Move.from(square, {?h, 4}),
      Move.from(square, {?a, 4}),
      Move.from(square, {?b, 4}),
      Move.from(square, {?c, 4}),
      Move.from(square, {?d, 4}),
      Move.from(square, {?e, 1}),
      Move.from(square, {?e, 2}),
      Move.from(square, {?e, 3}),
      Move.from(square, {?e, 5}),
      Move.from(square, {?e, 6}),
      Move.from(square, {?e, 7}),
      Move.from(square, {?e, 8})
    ])
  end

  test "with interposing pieces" do
    #   ┌───┬───┬───┬───┬───┬───┬───┬───┐
    # 8 │   │   │   │   │   │   │   │   │
    #   ├───┼───┼───┼───┼───┼───┼───┼───┤
    # 7 │   │   │   │   │   │   │   │   │
    #   ├───┼───┼───┼───┼───┼───┼───┼───┤
    # 6 │   │   │   │   │   │   │   │   │
    #   ├───┼───┼───┼───┼───┼───┼───┼───┤
    # 5 │   │   │   │   │   │   │   │   │
    #   ├───┼───┼───┼───┼───┼───┼───┼───┤
    # 4 │   │   │   │   │ ♗ │   │ ♜ │   │
    #   ├───┼───┼───┼───┼───┼───┼───┼───┤
    # 3 │   │   │   │   │   │   │   │   │
    #   ├───┼───┼───┼───┼───┼───┼───┼───┤
    # 2 │   │   │   │   │   │   │   │   │
    #   ├───┼───┼───┼───┼───┼───┼───┼───┤
    # 1 │   │   │   │   │   │   │ ♞ │   │
    #   └───┴───┴───┴───┴───┴───┴───┴───┘
    #     a   b   c   d   e   f   g   h
    game = Elchesser.Fen.parse("8/8/8/8/4B1r1/8/8/6n1 w KQkq - 0 1")
    square = Game.get_square(game, {?g, 4})

    assert Rook.moves(square, game) == Rook.attacks(square, game)

    Rook.moves(square, game)
    |> assert_list_eq_any_order([
      Move.from(square, {?h, 4}),
      Move.from(square, {?e, 4}, capture: true),
      Move.from(square, {?f, 4}),
      Move.from(square, {?g, 8}),
      Move.from(square, {?g, 7}),
      Move.from(square, {?g, 6}),
      Move.from(square, {?g, 5}),
      Move.from(square, {?g, 3}),
      Move.from(square, {?g, 2})
    ])
  end
end
