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
      %Move{file: ?h, rank: 1},
      %Move{file: ?f, rank: 1},
      %Move{file: ?f, rank: 3},
      %Move{file: ?e, rank: 4},
      %Move{file: ?d, rank: 5},
      %Move{file: ?c, rank: 6},
      %Move{file: ?b, rank: 7},
      %Move{file: ?a, rank: 8},
      %Move{file: ?h, rank: 3},
      %Move{file: ?h, rank: 2},
      %Move{file: ?a, rank: 2},
      %Move{file: ?b, rank: 2},
      %Move{file: ?c, rank: 2},
      %Move{file: ?d, rank: 2},
      %Move{file: ?e, rank: 2},
      %Move{file: ?f, rank: 2},
      %Move{file: ?g, rank: 1},
      %Move{file: ?g, rank: 3},
      %Move{file: ?g, rank: 4},
      %Move{file: ?g, rank: 5},
      %Move{file: ?g, rank: 6},
      %Move{file: ?g, rank: 7},
      %Move{file: ?g, rank: 8}
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
      %Move{file: ?h, rank: 2},
      %Move{file: ?h, rank: 3},
      %Move{file: ?h, rank: 1},
      %Move{file: ?g, rank: 1},
      %Move{file: ?f, rank: 1},
      %Move{file: ?g, rank: 3},
      %Move{file: ?g, rank: 4, capture: true},
      %Move{file: ?f, rank: 3},
      %Move{file: ?e, rank: 4},
      %Move{file: ?d, rank: 5},
      %Move{file: ?c, rank: 6},
      %Move{file: ?b, rank: 7, capture: true}
    ])
  end
end
