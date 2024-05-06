defmodule Elchesser.GameTest do
  use ExUnit.Case, async: true

  alias Elchesser.{Game, Move}

  describe "new/0" do
    game = Game.new()

    assert game.active == :w
    assert game.moves == []
    assert game.captures == []
  end

  describe "move/2" do
    test "works for standard opening move" do
      {:ok, game} = Game.new() |> Game.move(Move.from({?e, 2}, {?e, 4}))

      assert Game.get_square(game, {?e, 4}).piece == :P
    end

    test "errors when no piece at a square" do
      assert {:error, :empty_square} = Game.new() |> Game.move(Move.from({?e, 4}, {?e, 6}))
    end

    test "errors when attempting to move a piece of the wrong color" do
      assert {:error, :invalid_from_color} = Game.new() |> Game.move(Move.from({?e, 7}, {?e, 5}))
    end

    test "errors when attempting to put piece on occupied square" do
      assert {:error, :invalid_to_color} = Game.new() |> Game.move(Move.from({?a, 1}, {?b, 1}))
    end

    test "errors when move is invalid" do
      assert {:error, :invalid_move} = Game.new() |> Game.move(Move.from({?e, 2}, {?e, 5}))
    end

    test "properly updates the active move" do
      {:ok, game} = Game.new() |> Game.move(Move.from({?e, 2}, {?e, 4}))
      assert game.active == :b
      {:ok, game} = Game.move(game, Move.from({?e, 7}, {?e, 5}))
      assert game.active == :w
    end

    test "properly sets en_passant field" do
      {:ok, game} = Game.new() |> Game.move(Move.from({?e, 2}, {?e, 4}))
      assert game.en_passant == {?e, 3}
    end

    test "properly clears en_passant field" do
      {:ok, game} =
        Game.new()
        |> Game.move!(Move.from({?d, 2}, {?d, 4}))
        |> Game.move(Move.from({?g, 8}, {?f, 6}))

      assert game.en_passant == nil
    end

    test "updates half_moves properly" do
      {:ok, game} =
        Game.new()
        |> Game.move!(Move.from({?b, 1}, {?c, 3}))
        |> Game.move!(Move.from({?b, 8}, {?c, 6}))
        |> Game.move!(Move.from({?g, 1}, {?f, 3}))
        |> Game.move(Move.from({?g, 8}, {?f, 6}))

      assert game.half_moves == 4
    end

    test "resets half moves when pawn moves" do
      {:ok, game} =
        Game.new()
        |> Game.move!(Move.from({?b, 1}, {?c, 3}))
        |> Game.move!(Move.from({?b, 8}, {?c, 6}))
        |> Game.move!(Move.from({?g, 1}, {?f, 3}))
        |> Game.move!(Move.from({?g, 8}, {?f, 6}))
        |> Game.move(Move.from({?e, 2}, {?e, 4}))

      assert game.half_moves == 0
    end

    test "resets half moves after capture" do
      {:ok, game} =
        Game.new()
        |> Game.move!(Move.from({?b, 1}, {?c, 3}))
        |> Game.move!(Move.from({?b, 8}, {?c, 6}))
        |> Game.move!(Move.from({?c, 3}, {?d, 5}))
        |> Game.move(Move.from({?g, 8}, {?f, 6}))

      assert game.half_moves == 4

      {:ok, game} = Game.move(game, Move.from({?d, 5}, {?f, 6}))

      assert game.half_moves == 0
    end

    test "properly increments full clock after black moves" do
      game = Game.new()
      assert game.full_moves == 1
      {:ok, game} = Game.move(game, Move.from({?e, 2}, {?e, 4}))
      assert game.full_moves == 1
      {:ok, game} = Game.move(game, Move.from({?e, 7}, {?e, 5}))
      assert game.full_moves == 2
      {:ok, game} = Game.move(game, Move.from({?d, 2}, {?d, 4}))
      assert game.full_moves == 2
      {:ok, game} = Game.move(game, Move.from({?e, 5}, {?d, 4}))
      assert game.full_moves == 3
    end

    test "removes castling rights after king moves" do
      {:ok, game} =
        Game.new()
        |> Game.move!(Move.from({?e, 2}, {?e, 3}))
        |> Game.move(Move.from({?e, 7}, {?e, 6}))

      assert game.castling == MapSet.new([:K, :Q, :k, :q])

      {:ok, game} = Game.move(game, Move.from({?e, 1}, {?e, 2}))
      assert game.castling == MapSet.new([:k, :q])

      {:ok, game} = Game.move(game, Move.from({?e, 8}, {?e, 7}))
      assert game.castling == MapSet.new()
    end

    test "remove kingside castling rights after kingside rook moves" do
      {:ok, game} =
        Game.new()
        |> Game.move!(Move.from({?h, 2}, {?h, 3}))
        |> Game.move(Move.from({?h, 7}, {?h, 6}))

      assert game.castling == MapSet.new([:K, :Q, :k, :q])

      {:ok, game} = Game.move(game, Move.from({?h, 1}, {?h, 2}))
      assert game.castling == MapSet.new([:Q, :k, :q])

      {:ok, game} = Game.move(game, Move.from({?h, 8}, {?h, 7}))
      assert game.castling == MapSet.new([:Q, :q])
    end

    test "remove queenside castling rights after queenside rook moves" do
      {:ok, game} =
        Game.new()
        |> Game.move!(Move.from({?a, 2}, {?a, 3}))
        |> Game.move(Move.from({?a, 7}, {?a, 6}))

      assert game.castling == MapSet.new([:K, :Q, :k, :q])

      {:ok, game} = Game.move(game, Move.from({?a, 1}, {?a, 2}))
      assert game.castling == MapSet.new([:K, :k, :q])

      {:ok, game} = Game.move(game, Move.from({?a, 8}, {?a, 7}))
      assert game.castling == MapSet.new([:K, :k])
    end

    test "properly handles moving into and out of check" do
      game = Elchesser.Fen.parse("4K3/7r/8/8/8/8/8/8 b - - 0 1")
      assert game.check == false

      {:ok, game} = Game.move(game, Move.from({?h, 7}, {?h, 8}))
      assert game.check == true

      {:ok, game} = Game.move(game, Move.from({?e, 8}, {?e, 7}))
      assert game.check == false
    end

    test "handles promotion properly" do
      game = Elchesser.Fen.parse("4k3/7P/8/8/8/8/8/8 w - - 0 1")

      {:ok, game} = Game.move(game, Move.from({?h, 7}, {?h, 8}, promotion: :R))
      assert Game.get_square(game, {?h, 8}).piece == :R
      assert game.check == true
    end
  end
end
