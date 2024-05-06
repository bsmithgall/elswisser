defmodule Elchesser.BoardTest do
  use ExUnit.Case, async: true

  alias Elchesser.{Move, Board, Game, Square}

  describe "move/2 no castling" do
    # all tests starting from this position
    #   ┌───┬───┬───┬───┬───┬───┬───┬───┐
    # 8 │   │   │   │   │ ♚ │ ♘ │   │ ♜ │
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
    setup do
      {:ok, game: Elchesser.Fen.parse("4kN1r/8/8/8/8/8/8/8 w k - 0 1")}
    end

    test "cannot move a piece from an empty square", %{game: game} do
      assert Board.move(game, Move.from({?a, 1}, {?b, 1})) == {:error, :empty_square}
    end

    test "cannot move a piece onto a friendly piece square", %{game: game} do
      assert Board.move(game, Move.from({?e, 8}, {?h, 8})) == {:error, :invalid_to_color}
    end

    test "can successfully move onto an empty square", %{game: game} do
      {:ok, {piece, capture, game}} = Board.move(game, Move.from({?e, 8}, {?d, 8}))

      assert piece == :k
      assert is_nil(capture)
      assert Game.get_square(game, Square.from(?d, 8)).piece == :k
      assert Game.get_square(game, Square.from(?e, 8)).piece == nil
    end

    test "can successfully capture an enemy piece", %{game: game} do
      {:ok, {piece, capture, game}} = Board.move(game, Move.from({?e, 8}, {?f, 8}))

      assert piece == :k
      assert capture == :N
      assert Game.get_square(game, Square.from(?f, 8)).piece == :k
      assert Game.get_square(game, Square.from(?e, 8)).piece == nil
    end
  end

  describe "move/2 castling" do
    test "white castle kingside" do
      game = Elchesser.Fen.parse("8/8/8/8/8/8/8/4K2R w KQkq - 0 1")
      {:ok, {piece, capture, game}} = Board.move(game, Move.from({?e, 1}, {?g, 1}, castle: true))

      assert piece == :K
      assert is_nil(capture)
      assert Game.get_square(game, Square.from(?f, 1)).piece == :R
      assert Game.get_square(game, Square.from(?g, 1)).piece == :K
    end

    test "white castle queenside" do
      game = Elchesser.Fen.parse("8/8/8/8/8/8/8/R3K3 w KQkq - 0 1")
      {:ok, {piece, capture, game}} = Board.move(game, Move.from({?e, 1}, {?c, 1}, castle: true))

      assert piece == :K
      assert is_nil(capture)
      assert Game.get_square(game, Square.from(?d, 1)).piece == :R
      assert Game.get_square(game, Square.from(?c, 1)).piece == :K
    end

    test "black castle kingside" do
      game = Elchesser.Fen.parse("4k2r/8/8/8/8/8/8/8 w KQkq - 0 1")
      {:ok, {piece, capture, game}} = Board.move(game, Move.from({?e, 8}, {?g, 8}, castle: true))

      assert piece == :k
      assert is_nil(capture)
      assert Game.get_square(game, Square.from(?f, 8)).piece == :r
      assert Game.get_square(game, Square.from(?g, 8)).piece == :k
    end

    test "black castle queenside" do
      game = Elchesser.Fen.parse("r3k3/8/8/8/8/8/8/8 w KQkq - 0 1")
      {:ok, {piece, capture, game}} = Board.move(game, Move.from({?e, 8}, {?c, 8}, castle: true))

      assert piece == :k
      assert is_nil(capture)
      assert Game.get_square(game, Square.from(?d, 8)).piece == :r
      assert Game.get_square(game, Square.from(?c, 8)).piece == :k
    end
  end

  describe "move/2 promotion" do
    test "no capture" do
      game = Elchesser.Fen.parse("8/P7/8/8/8/8/8/8 w KQkq - 0 1")
      {:ok, {piece, capture, game}} = Board.move(game, Move.from({?a, 7}, {?a, 8}, promotion: :Q))

      assert piece == :P
      assert is_nil(capture)
      assert Game.get_square(game, Square.from(?a, 8)).piece == :Q
    end

    test "capture" do
      game = Elchesser.Fen.parse("1n6/P7/8/8/8/8/8/8 w KQkq - 0 1")
      {:ok, {piece, capture, game}} = Board.move(game, Move.from({?a, 7}, {?b, 8}, promotion: :N))

      assert piece == :P
      assert capture == :n
      assert Game.get_square(game, Square.from(?b, 8)).piece == :N
    end
  end
end
