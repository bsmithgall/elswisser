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
      %Move{file: ?g, rank: 5},
      %Move{file: ?h, rank: 4},
      %Move{file: ?e, rank: 5},
      %Move{file: ?d, rank: 4},
      %Move{file: ?c, rank: 3},
      %Move{file: ?b, rank: 2},
      %Move{file: ?a, rank: 1},
      %Move{file: ?e, rank: 7},
      %Move{file: ?d, rank: 8},
      %Move{file: ?g, rank: 7},
      %Move{file: ?h, rank: 8}
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
      %Move{file: ?c, rank: 1},
      %Move{file: ?a, rank: 1},
      %Move{file: ?c, rank: 3},
      %Move{file: ?d, rank: 4},
      %Move{file: ?e, rank: 5},
      %Move{file: ?f, rank: 6},
      %Move{file: ?g, rank: 7, capture: true}
    ])
  end
end
