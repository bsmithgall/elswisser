defmodule Elchesser.Piece.PawnTest do
  use ExUnit.Case, async: true

  alias Elchesser.{Game, Move}
  alias Elchesser.Piece.Pawn

  import TestHelper

  describe "white pieces" do
    test "second rank only pawn" do
      game = Elchesser.Fen.parse("8/8/8/8/8/8/4P3/8 w KQkq - 0 1")
      square = Game.get_square(game, {?e, 2})

      assert_list_eq_any_order(Pawn.moves(square, game), [
        Move.from(square, {?e, 3}),
        Move.from(square, {?e, 4})
      ])

      assert_list_eq_any_order(Pawn.attacks(square, game), [
        Move.from(square, {?d, 3}),
        Move.from(square, {?f, 3})
      ])
    end

    test "third rank only pawn" do
      game = Elchesser.Fen.parse("8/8/8/8/8/P7/8/8 w KQkq - 0 1")
      square = Game.get_square(game, {?a, 3})

      assert_list_eq_any_order(Pawn.moves(square, game), [
        Move.from(square, {?a, 4})
      ])

      assert_list_eq_any_order(Pawn.attacks(square, game), [
        Move.from(square, {?b, 4})
      ])
    end

    test "second rank with captures" do
      game = Elchesser.Fen.parse("8/8/8/8/8/5p2/4P3/8 w KQkq - 0 1")
      square = Game.get_square(game, {?e, 2})

      assert_list_eq_any_order(Pawn.moves(square, game), [
        Move.from(square, {?e, 3}),
        Move.from(square, {?e, 4}),
        Move.from(square, {?f, 3}, capture: true)
      ])
    end

    test "third rank with captures" do
      game = Elchesser.Fen.parse("8/8/8/8/pp5p/P7/8/8 w KQkq - 0 1")
      square = Game.get_square(game, {?a, 3})

      assert Pawn.moves(square, game) == [
               Move.from(square, {?b, 4}, capture: true)
             ]
    end

    test "en-passant" do
      game = Elchesser.Fen.parse("rnbqkbnr/ppp1p1pp/8/3pPp2/8/8/PPPP1PPP/RNBQKBNR w KQkq f6 0 2")
      square = Game.get_square(game, {?e, 5})

      assert_list_eq_any_order(Pawn.moves(square, game), [
        Move.from(square, {?e, 6}),
        Move.from(square, {?f, 6}, capture: true)
      ])
    end
  end

  describe "black pieces" do
    test "seventh rank only pawn" do
      game = Elchesser.Fen.parse("8/4p3/8/8/8/8/8/8 w KQkq - 0 1")
      square = Game.get_square(game, {?e, 7})

      assert_list_eq_any_order(Pawn.moves(square, game), [
        Move.from(square, {?e, 6}),
        Move.from(square, {?e, 5})
      ])
    end

    test "sixth rank only pawn" do
      game = Elchesser.Fen.parse("8/8/7p/8/8/8/8/8 w KQkq - 0 1")
      square = Game.get_square(game, {?h, 6})

      assert_list_eq_any_order(Pawn.moves(square, game), [
        Move.from(square, {?h, 5})
      ])
    end

    test "seventh rank with captures" do
      game = Elchesser.Fen.parse("8/4p3/5P2/8/8/8/8/8 w KQkq - 0 1")
      square = Game.get_square(game, {?e, 7})

      assert_list_eq_any_order(Pawn.moves(square, game), [
        Move.from(square, {?e, 6}),
        Move.from(square, {?e, 5}),
        Move.from(square, {?f, 6}, capture: true)
      ])
    end

    test "sixth rank with captures" do
      game = Elchesser.Fen.parse("8/8/7p/PPPPPPPP/8/8/8/8 w KQkq - 0 1")
      square = Game.get_square(game, {?h, 6})

      assert_list_eq_any_order(Pawn.moves(square, game), [
        Move.from(square, {?g, 5}, capture: true)
      ])
    end

    test "en-passant" do
      game = Elchesser.Fen.parse("rnbqkbnr/pppp1ppp/8/8/3PpP2/8/PPP1P1PP/RNBQKBNR w KQkq d3 0 2")
      square = Game.get_square(game, {?e, 4})

      assert_list_eq_any_order(Pawn.moves(square, game), [
        Move.from(square, {?e, 3}),
        Move.from(square, {?d, 3}, capture: true)
      ])
    end
  end
end
