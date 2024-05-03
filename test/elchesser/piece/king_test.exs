defmodule Elchesser.Piece.KingTest do
  use ExUnit.Case, async: true

  alias Elchesser.{Game, Move}
  alias Elchesser.Piece.King

  import TestHelper

  describe "white king" do
    test "only king on the board" do
      game = Elchesser.Fen.parse("8/8/2K5/8/8/8/8/8 w - - 0 1")
      square = Game.get_square(game, {?c, 6})

      assert_list_eq_any_order(King.moves(square, game), [
        Move.from({?b, 7}),
        Move.from({?c, 7}),
        Move.from({?d, 7}),
        Move.from({?b, 6}),
        Move.from({?d, 6}),
        Move.from({?b, 5}),
        Move.from({?c, 5}),
        Move.from({?d, 5})
      ])
    end

    test "king in the corner" do
      game = Elchesser.Fen.parse("K7/8/8/8/8/8/8/8 w - - 0 1")
      square = Game.get_square(game, {?a, 8})

      assert_list_eq_any_order(King.moves(square, game), [
        Move.from({?b, 8}),
        Move.from({?b, 7}),
        Move.from({?a, 7})
      ])
    end

    test "king surrounded by friendly pawns" do
      game = Elchesser.Fen.parse("KP6/PP6/8/8/8/8/8/8 w - - 0 1")
      square = Game.get_square(game, {?a, 8})

      assert King.moves(square, game) == []
    end

    test "can castle when valid" do
      game = Elchesser.Fen.parse("8/8/8/8/8/8/8/4K2R w K - 0 1")
      square = Game.get_square(game, {?e, 1})

      assert_list_eq_any_order(King.moves(square, game), [
        %Move{file: ?d, rank: 1},
        %Move{file: ?d, rank: 2},
        %Move{file: ?e, rank: 2},
        %Move{file: ?f, rank: 2},
        %Move{file: ?f, rank: 1},
        %Move{file: ?g, rank: 1, castle: true}
      ])
    end

    test "cannot castle without correct game state" do
      game = Elchesser.Fen.parse("8/8/8/8/8/8/8/4K2R w - - 0 1")
      square = Game.get_square(game, {?e, 1})

      assert_list_eq_any_order(King.moves(square, game), [
        %Move{file: ?d, rank: 1},
        %Move{file: ?d, rank: 2},
        %Move{file: ?e, rank: 2},
        %Move{file: ?f, rank: 2},
        %Move{file: ?f, rank: 1}
      ])
    end

    test "cannot castle when blocked by friendly piece" do
      game = Elchesser.Fen.parse("8/8/8/8/8/8/8/4KN1R w K - 0 1")
      square = Game.get_square(game, {?e, 1})

      assert_list_eq_any_order(King.moves(square, game), [
        %Move{file: ?d, rank: 1},
        %Move{file: ?d, rank: 2},
        %Move{file: ?e, rank: 2},
        %Move{file: ?f, rank: 2}
      ])
    end

    test "cannot castle when blocked by enemy piece" do
      game = Elchesser.Fen.parse("8/8/8/8/8/8/8/4Kn1R w K - 0 1")
      square = Game.get_square(game, {?e, 1})

      assert_list_eq_any_order(King.moves(square, game), [
        %Move{file: ?d, rank: 1},
        %Move{file: ?e, rank: 2},
        %Move{file: ?f, rank: 2},
        %Move{file: ?f, rank: 1, capture: true}
      ])
    end

    test "cannot castle into check" do
      game = Elchesser.Fen.parse("8/8/8/8/8/8/6r1/4K2R w K - 0 1")
      square = Game.get_square(game, {?e, 1})

      assert_list_eq_any_order(King.moves(square, game), [
        %Move{file: ?d, rank: 1},
        %Move{file: ?f, rank: 1}
      ])
    end

    test "cannot castle through attacked squares" do
      game = Elchesser.Fen.parse("8/8/8/8/8/5r2/8/4K2R w K - 0 1")
      square = Game.get_square(game, {?e, 1})

      assert_list_eq_any_order(King.moves(square, game), [
        %Move{file: ?d, rank: 1},
        %Move{file: ?d, rank: 2},
        %Move{file: ?e, rank: 2}
      ])
    end

    test "can castle kingside when rook is attacked but not king" do
      game = Elchesser.Fen.parse("8/8/8/8/8/7r/8/4K2R w K - 0 1")
      square = Game.get_square(game, {?e, 1})

      assert_list_eq_any_order(King.moves(square, game), [
        %Move{file: ?d, rank: 1},
        %Move{file: ?d, rank: 2},
        %Move{file: ?e, rank: 2},
        %Move{file: ?f, rank: 2},
        %Move{file: ?f, rank: 1},
        %Move{file: ?g, rank: 1, castle: true}
      ])
    end

    test "can castle queenside" do
      game = Elchesser.Fen.parse("8/8/8/8/8/8/8/R3K3 w Q - 0 1")
      square = Game.get_square(game, {?e, 1})

      assert_list_eq_any_order(King.moves(square, game), [
        %Move{file: ?d, rank: 1},
        %Move{file: ?d, rank: 2},
        %Move{file: ?e, rank: 2},
        %Move{file: ?f, rank: 2},
        %Move{file: ?f, rank: 1},
        %Move{file: ?c, rank: 1, castle: true}
      ])
    end

    test "can castle either way" do
      game = Elchesser.Fen.parse("8/8/8/8/8/8/8/R3K2R w KQ - 0 1")
      square = Game.get_square(game, {?e, 1})

      assert_list_eq_any_order(King.moves(square, game), [
        %Move{file: ?d, rank: 1},
        %Move{file: ?d, rank: 2},
        %Move{file: ?e, rank: 2},
        %Move{file: ?f, rank: 2},
        %Move{file: ?f, rank: 1},
        %Move{file: ?g, rank: 1, castle: true},
        %Move{file: ?c, rank: 1, castle: true}
      ])
    end

    test "can castle when b file is attacked" do
      game = Elchesser.Fen.parse("8/8/8/8/8/1r6/8/R3K2R w Q - 0 1")
      square = Game.get_square(game, {?e, 1})

      assert_list_eq_any_order(King.moves(square, game), [
        %Move{file: ?d, rank: 1},
        %Move{file: ?d, rank: 2},
        %Move{file: ?e, rank: 2},
        %Move{file: ?f, rank: 2},
        %Move{file: ?f, rank: 1},
        %Move{file: ?c, rank: 1, castle: true}
      ])
    end
  end

  describe "black king" do
    test "only king on the board" do
      game = Elchesser.Fen.parse("8/8/2k5/8/8/8/8/8 w - - 0 1")
      square = Game.get_square(game, {?c, 6})

      assert_list_eq_any_order(King.moves(square, game), [
        Move.from({?b, 7}),
        Move.from({?c, 7}),
        Move.from({?d, 7}),
        Move.from({?b, 6}),
        Move.from({?d, 6}),
        Move.from({?b, 5}),
        Move.from({?c, 5}),
        Move.from({?d, 5})
      ])
    end

    test "king in the corner" do
      game = Elchesser.Fen.parse("k7/8/8/8/8/8/8/8 w - - 0 1")
      square = Game.get_square(game, {?a, 8})

      assert_list_eq_any_order(King.moves(square, game), [
        Move.from({?b, 8}),
        Move.from({?b, 7}),
        Move.from({?a, 7})
      ])
    end

    test "king surrounded by friendly pawns" do
      game = Elchesser.Fen.parse("kp6/pp6/8/8/8/8/8/8 w - - 0 1")
      square = Game.get_square(game, {?a, 8})

      assert King.moves(square, game) == []
    end

    test "can castle when valid" do
      game = Elchesser.Fen.parse("4k2r/8/8/8/8/8/8/8 w k - 0 1")
      square = Game.get_square(game, {?e, 8})

      assert_list_eq_any_order(King.moves(square, game), [
        %Move{file: ?d, rank: 8},
        %Move{file: ?d, rank: 7},
        %Move{file: ?e, rank: 7},
        %Move{file: ?f, rank: 7},
        %Move{file: ?f, rank: 8},
        %Move{file: ?g, rank: 8, castle: true}
      ])
    end

    test "cannot castle without correct game state" do
      game = Elchesser.Fen.parse("4k2r/8/8/8/8/8/8/8 w - - 0 1")
      square = Game.get_square(game, {?e, 8})

      assert_list_eq_any_order(King.moves(square, game), [
        %Move{file: ?d, rank: 8},
        %Move{file: ?d, rank: 7},
        %Move{file: ?e, rank: 7},
        %Move{file: ?f, rank: 7},
        %Move{file: ?f, rank: 8}
      ])
    end

    test "cannot castle when blocked by friendly piece" do
      game = Elchesser.Fen.parse("4kn1r/8/8/8/8/8/8/4KN1R w k - 0 1")
      square = Game.get_square(game, {?e, 8})

      assert_list_eq_any_order(King.moves(square, game), [
        %Move{file: ?d, rank: 8},
        %Move{file: ?d, rank: 7},
        %Move{file: ?e, rank: 7},
        %Move{file: ?f, rank: 7}
      ])
    end

    test "cannot castle when blocked by enemy piece" do
      game = Elchesser.Fen.parse("4kN1r/8/8/8/8/8/8/8 w k - 0 1")
      square = Game.get_square(game, {?e, 8})

      assert_list_eq_any_order(King.moves(square, game), [
        %Move{file: ?d, rank: 8},
        %Move{file: ?e, rank: 7},
        %Move{file: ?f, rank: 7},
        %Move{file: ?f, rank: 8, capture: true}
      ])
    end

    test "cannot castle into check" do
      game = Elchesser.Fen.parse("4k2r/6R1/8/8/8/8/6r1/8 w k - 0 1")
      square = Game.get_square(game, {?e, 8})

      assert_list_eq_any_order(King.moves(square, game), [
        %Move{file: ?d, rank: 8},
        %Move{file: ?f, rank: 8}
      ])
    end

    test "cannot castle through attacked squares" do
      game = Elchesser.Fen.parse("4k2r/8/5R2/8/8/8/8/8 w k - 0 1")
      square = Game.get_square(game, {?e, 8})

      assert_list_eq_any_order(King.moves(square, game), [
        %Move{file: ?d, rank: 8},
        %Move{file: ?d, rank: 7},
        %Move{file: ?e, rank: 7}
      ])
    end

    test "can castle kingside when rook is attacked but not king" do
      game = Elchesser.Fen.parse("4k2r/8/7R/8/8/8/8/8 w k - 0 1")
      square = Game.get_square(game, {?e, 8})

      assert_list_eq_any_order(King.moves(square, game), [
        %Move{file: ?d, rank: 8},
        %Move{file: ?d, rank: 7},
        %Move{file: ?e, rank: 7},
        %Move{file: ?f, rank: 7},
        %Move{file: ?f, rank: 8},
        %Move{file: ?g, rank: 8, castle: true}
      ])
    end

    test "can castle queenside" do
      game = Elchesser.Fen.parse("r3k3/8/8/8/8/8/8/8 w q - 0 1")
      square = Game.get_square(game, {?e, 8})

      assert_list_eq_any_order(King.moves(square, game), [
        %Move{file: ?d, rank: 8},
        %Move{file: ?d, rank: 7},
        %Move{file: ?e, rank: 7},
        %Move{file: ?f, rank: 7},
        %Move{file: ?f, rank: 8},
        %Move{file: ?c, rank: 8, castle: true}
      ])
    end

    test "can castle either way" do
      game = Elchesser.Fen.parse("r3k2r/8/8/8/8/8/8/8 w kq - 0 1")
      square = Game.get_square(game, {?e, 8})

      assert_list_eq_any_order(King.moves(square, game), [
        %Move{file: ?d, rank: 8},
        %Move{file: ?d, rank: 7},
        %Move{file: ?e, rank: 7},
        %Move{file: ?f, rank: 7},
        %Move{file: ?f, rank: 8},
        %Move{file: ?g, rank: 8, castle: true},
        %Move{file: ?c, rank: 8, castle: true}
      ])
    end

    test "can castle when b file is attacked" do
      game = Elchesser.Fen.parse("r3k2r/8/1R6/8/8/8/8/8 w q - 0 1")
      square = Game.get_square(game, {?e, 8})

      assert_list_eq_any_order(King.moves(square, game), [
        %Move{file: ?d, rank: 8},
        %Move{file: ?d, rank: 7},
        %Move{file: ?e, rank: 7},
        %Move{file: ?f, rank: 7},
        %Move{file: ?f, rank: 8},
        %Move{file: ?c, rank: 8, castle: true}
      ])
    end
  end
end
