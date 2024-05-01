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
      %Move{file: ?f, rank: 4},
      %Move{file: ?g, rank: 4},
      %Move{file: ?h, rank: 4},
      %Move{file: ?a, rank: 4},
      %Move{file: ?b, rank: 4},
      %Move{file: ?c, rank: 4},
      %Move{file: ?d, rank: 4},
      %Move{file: ?e, rank: 1},
      %Move{file: ?e, rank: 2},
      %Move{file: ?e, rank: 3},
      %Move{file: ?e, rank: 5},
      %Move{file: ?e, rank: 6},
      %Move{file: ?e, rank: 7},
      %Move{file: ?e, rank: 8}
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
      %Move{file: ?h, rank: 4},
      %Move{file: ?e, rank: 4, capture: true},
      %Move{file: ?f, rank: 4},
      %Move{file: ?g, rank: 8},
      %Move{file: ?g, rank: 7},
      %Move{file: ?g, rank: 6},
      %Move{file: ?g, rank: 5},
      %Move{file: ?g, rank: 3},
      %Move{file: ?g, rank: 2}
    ])
  end
end
