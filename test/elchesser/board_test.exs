defmodule Elchesser.BoardTest do
  use ExUnit.Case, async: true

  alias Elchesser.{Move, Board, Game, Square}

  describe "move/2" do
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
end
