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
      assert Board.move(game, Move.from({?a, 1, :R}, {?b, 1})) == {:error, :empty_square}
    end

    test "cannot move a piece onto a friendly piece square", %{game: game} do
      assert Board.move(game, Move.from({?e, 8, :k}, {?h, 8})) == {:error, :invalid_to_color}
    end

    test "can successfully move onto an empty square", %{game: game} do
      {:ok, {move, game}} = Board.move(game, Move.from({?e, 8, :k}, {?d, 8}))

      assert move.piece == :k
      assert is_nil(move.capture)
      assert Game.get_square(game, Square.from(?d, 8)).piece == :k
      assert Game.get_square(game, Square.from(?e, 8)).piece == nil
    end

    test "can successfully capture an enemy piece", %{game: game} do
      {:ok, {move, game}} = Board.move(game, Move.from({?e, 8, :k}, {?f, 8}))

      assert move.piece == :k
      assert move.capture == :N
      assert Game.get_square(game, Square.from(?f, 8)).piece == :k
      assert Game.get_square(game, Square.from(?e, 8)).piece == nil
    end
  end

  describe "move/2 castling" do
    test "white castle kingside" do
      game = Elchesser.Fen.parse("8/8/8/8/8/8/8/4K2R w KQkq - 0 1")

      {:ok, {move, game}} =
        Board.move(game, Move.from({?e, 1, :K}, {?g, 1}, castle: true))

      assert move.piece == :K
      assert is_nil(move.capture)
      assert Game.get_square(game, Square.from(?f, 1)).piece == :R
      assert Game.get_square(game, Square.from(?g, 1)).piece == :K
    end

    test "white castle queenside" do
      game = Elchesser.Fen.parse("8/8/8/8/8/8/8/R3K3 w KQkq - 0 1")

      {:ok, {move, game}} =
        Board.move(game, Move.from({?e, 1, :K}, {?c, 1}, castle: true))

      assert move.piece == :K
      assert is_nil(move.capture)
      assert Game.get_square(game, Square.from(?d, 1)).piece == :R
      assert Game.get_square(game, Square.from(?c, 1)).piece == :K
    end

    test "black castle kingside" do
      game = Elchesser.Fen.parse("4k2r/8/8/8/8/8/8/8 w KQkq - 0 1")

      {:ok, {move, game}} =
        Board.move(game, Move.from({?e, 8, :k}, {?g, 8}, castle: true))

      assert move.piece == :k
      assert is_nil(move.capture)
      assert Game.get_square(game, Square.from(?f, 8)).piece == :r
      assert Game.get_square(game, Square.from(?g, 8)).piece == :k
    end

    test "black castle queenside" do
      game = Elchesser.Fen.parse("r3k3/8/8/8/8/8/8/8 w KQkq - 0 1")

      {:ok, {move, game}} =
        Board.move(game, Move.from({?e, 8, :k}, {?c, 8}, castle: true))

      assert move.piece == :k
      assert is_nil(move.capture)
      assert Game.get_square(game, Square.from(?d, 8)).piece == :r
      assert Game.get_square(game, Square.from(?c, 8)).piece == :k
    end
  end

  describe "move/2 promotion" do
    test "no capture" do
      game = Elchesser.Fen.parse("8/P7/8/8/8/8/8/8 w KQkq - 0 1")

      {:ok, {move, game}} =
        Board.move(game, Move.from({?a, 7, :P}, {?a, 8}, promotion: :Q))

      assert move.piece == :P
      assert is_nil(move.capture)
      assert Game.get_square(game, Square.from(?a, 8)).piece == :Q
    end

    test "capture" do
      game = Elchesser.Fen.parse("1n6/P7/8/8/8/8/8/8 w KQkq - 0 1")

      {:ok, {move, game}} =
        Board.move(game, Move.from({?a, 7, :P}, {?b, 8}, promotion: :N))

      assert move.piece == :P
      assert move.capture == :n
      assert Game.get_square(game, Square.from(?b, 8)).piece == :N
    end
  end

  describe "move/2 various checkmates etc" do
    test "checkmate" do
      game =
        Elchesser.Fen.parse("r1bqkbnr/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 0 1")

      {:ok, {move, _game}} = Board.move(game, Move.from({?h, 5, :Q}, {?f, 7}))

      assert move.checking == :checkmate
      assert move.san == "Qxf7#"
    end

    test "stalemate" do
      game = Elchesser.Fen.parse("7K/8/8/5q2/8/8/8/5k2 b - - 0 1")

      {:ok, {move, _game}} = Board.move(game, Move.from({?f, 5, :q}, {?f, 7}))

      assert move.checking == :stalemate
      assert move.san == "Qf7="
    end
  end
end
