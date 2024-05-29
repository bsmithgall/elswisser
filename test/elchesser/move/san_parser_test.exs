defmodule Elchesser.Move.SanParserTest do
  use ExUnit.Case, async: true

  alias Elchesser.{Game, Move, Fen}
  alias Elchesser.Move.SanParser

  test "invalid move" do
    assert SanParser.parse("NOTAMOVE", Game.new()) == {:error, :invalid_move}
  end

  describe "pawns" do
    test "one-square pawn move" do
      assert SanParser.parse("e3", Game.new()) ==
               {:ok,
                %Move{
                  from: {?e, 2},
                  to: {?e, 3},
                  piece: :P,
                  capture: nil,
                  checking: nil,
                  castle: false
                }}
    end

    test "two-square starting pawn move" do
      assert SanParser.parse("e4", Game.new()) ==
               {:ok,
                %Move{
                  from: {?e, 2},
                  to: {?e, 4},
                  piece: :P,
                  capture: nil,
                  checking: nil,
                  castle: false,
                  promotion: nil
                }}
    end

    test "pawn captures a piece" do
      game = Fen.parse("8/8/8/8/pp5p/P7/8/8 w KQkq - 0 1")

      assert SanParser.parse("axb4", game) ==
               {:ok,
                %Move{
                  from: {?a, 3},
                  to: {?b, 4},
                  piece: :P,
                  capture: :p,
                  checking: nil,
                  castle: false,
                  promotion: nil
                }}
    end

    test "en passant capture" do
      game = Elchesser.Fen.parse("rnbqkbnr/pppp1ppp/8/8/3PpP2/8/PPP1P1PP/RNBQKBNR b KQkq d3 0 2")

      assert SanParser.parse("exd3", game) ==
               {:ok,
                %Move{
                  from: {?e, 4},
                  to: {?d, 3},
                  piece: :p,
                  capture: :P,
                  checking: nil,
                  castle: false,
                  promotion: nil
                }}
    end

    test "promotion with no capture" do
      game = Elchesser.Fen.parse("8/P7/8/8/8/8/8/8 w KQkq - 0 1")

      assert SanParser.parse("a8=Q", game) ==
               {:ok,
                %Move{
                  from: {?a, 7},
                  to: {?a, 8},
                  piece: :P,
                  capture: nil,
                  checking: nil,
                  castle: false,
                  promotion: :Q
                }}
    end

    test "promotion with capture" do
      game = Elchesser.Fen.parse("1r6/P7/8/8/8/8/8/8 w KQkq - 0 1")

      assert SanParser.parse("axb8=B", game) ==
               {:ok,
                %Move{
                  from: {?a, 7},
                  to: {?b, 8},
                  piece: :P,
                  capture: :r,
                  checking: nil,
                  castle: false,
                  promotion: :B
                }}
    end

    test "underpromotion with capture and check" do
      game = Elchesser.Fen.parse("8/8/8/8/8/8/7p/K5B1 b KQkq - 0 1")

      assert SanParser.parse("hxg1=R+", game) ==
               {:ok,
                %Move{
                  from: {?h, 2},
                  to: {?g, 1},
                  piece: :p,
                  capture: :B,
                  checking: :check,
                  castle: false,
                  promotion: :r
                }}
    end
  end

  describe "pieces" do
    test "rooks" do
      game = Elchesser.Fen.parse("R7/8/8/8/8/8/8/b7 w - - 0 1")

      assert SanParser.parse("Rxa1", game) ==
               {:ok,
                %Move{
                  from: {?a, 8},
                  to: {?a, 1},
                  piece: :R,
                  capture: :b,
                  checking: nil,
                  castle: false,
                  promotion: nil
                }}
    end

    test "ambiguous rook moves" do
      game = Elchesser.Fen.parse("R7/8/8/8/8/8/8/R7 w - - 0 1")

      assert SanParser.parse("R8a4", game) ==
               {:ok,
                %Move{
                  from: {?a, 8},
                  to: {?a, 4},
                  piece: :R,
                  capture: nil,
                  checking: nil,
                  castle: false,
                  promotion: nil
                }}
    end

    test "knights" do
      game = Elchesser.Fen.parse("n7/3K4/8/8/8/8/8/8 b - - 0 1")

      assert SanParser.parse("Nb6+", game) ==
               {:ok,
                %Move{
                  from: {?a, 8},
                  to: {?b, 6},
                  piece: :n,
                  capture: nil,
                  checking: :check,
                  castle: false,
                  promotion: nil
                }}
    end

    test "ambiguous knight moves" do
      game = Elchesser.Fen.parse("n1n5/3K4/8/3n4/n7/8/8/8 b - - 0 1")

      assert SanParser.parse("Nd5b6+", game) ==
               {:ok,
                %Move{
                  from: {?d, 5},
                  to: {?b, 6},
                  piece: :n,
                  capture: nil,
                  checking: :check,
                  castle: false,
                  promotion: nil
                }}
    end

    test "bishops" do
      game = Elchesser.Fen.parse("B7/8/8/8/8/8/8/8 w - - 0 1")

      assert SanParser.parse("Bh1", game) ==
               {:ok,
                %Move{
                  from: {?a, 8},
                  to: {?h, 1},
                  piece: :B,
                  capture: nil,
                  checking: nil,
                  castle: false,
                  promotion: nil
                }}
    end

    test "queens" do
      game =
        Elchesser.Fen.parse("r1bqk1nr/pppp1ppp/2n5/2b1p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 0 1")

      assert SanParser.parse("Qxf7#", game) ==
               {:ok,
                %Move{
                  from: {?h, 5},
                  to: {?f, 7},
                  piece: :Q,
                  capture: :p,
                  checking: :checkmate,
                  castle: false,
                  promotion: nil
                }}
    end

    test "kings -- non-castling" do
      game =
        Elchesser.Fen.parse(
          "r1b1k1nr/pppp1ppp/2n5/2bNp3/2B1P1Q1/8/PPPP1qPP/R1B1K1NR w KQkq - 0 6"
        )

      assert SanParser.parse("Kd1", game) ==
               {:ok,
                %Move{
                  from: {?e, 1},
                  to: {?d, 1},
                  piece: :K,
                  capture: nil,
                  checking: nil,
                  castle: false,
                  promotion: nil
                }}
    end
  end

  describe "castling" do
    test "white kingside" do
      game = Elchesser.Fen.parse("r3k2r/pppppppp/8/8/8/8/PPPPPPPP/R3K2R w KQkq - 0 1")

      assert SanParser.parse("O-O", game) ==
               {:ok,
                %Move{
                  from: {?e, 1},
                  to: {?g, 1},
                  piece: :K,
                  castle: true
                }}
    end

    test "black kingside" do
      game = Elchesser.Fen.parse("r3k2r/pppppppp/8/8/8/8/PPPPPPPP/R3K2R b KQkq - 0 1")

      assert SanParser.parse("O-O", game) ==
               {:ok,
                %Move{
                  from: {?e, 8},
                  to: {?g, 8},
                  piece: :k,
                  castle: true
                }}
    end

    test "white queenside" do
      game = Elchesser.Fen.parse("r3k2r/pppppppp/8/8/8/8/PPPPPPPP/R3K2R w KQkq - 0 1")

      assert SanParser.parse("O-O-O", game) ==
               {:ok,
                %Move{
                  from: {?e, 1},
                  to: {?c, 1},
                  piece: :K,
                  castle: true
                }}
    end

    test "black queenside" do
      game = Elchesser.Fen.parse("r3k2r/pppppppp/8/8/8/8/PPPPPPPP/R3K2R b KQkq - 0 1")

      assert SanParser.parse("O-O-O", game) ==
               {:ok,
                %Move{
                  from: {?e, 8},
                  to: {?c, 8},
                  piece: :k,
                  castle: true
                }}
    end
  end
end
