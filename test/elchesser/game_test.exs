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
      {:ok, game} = Game.new() |> Game.move(Move.from({?e, 2, :P}, {?e, 4}))

      assert Game.get_square(game, {?e, 4}).piece == :P
    end

    test "errors when no piece at a square" do
      assert {:error, :empty_square} = Game.new() |> Game.move(Move.from({?e, 4, :P}, {?e, 6}))
    end

    test "errors when attempting to move a piece of the wrong color" do
      assert {:error, :invalid_from_color} =
               Game.new() |> Game.move(Move.from({?e, 7, :P}, {?e, 5}))
    end

    test "errors when attempting to put piece on occupied square" do
      assert {:error, :invalid_to_color} =
               Game.new() |> Game.move(Move.from({?a, 1, :R}, {?b, 1}))
    end

    test "errors when move is invalid" do
      assert {:error, :invalid_move} = Game.new() |> Game.move(Move.from({?e, 2, :P}, {?e, 5}))
    end

    test "properly updates the active move" do
      {:ok, game} = Game.new() |> Game.move(Move.from({?e, 2, :P}, {?e, 4}))
      assert game.active == :b
      {:ok, game} = Game.move(game, Move.from({?e, 7, :p}, {?e, 5}))
      assert game.active == :w
    end

    test "properly sets en_passant field" do
      {:ok, game} = Game.new() |> Game.move(Move.from({?e, 2, :P}, {?e, 4}))
      assert game.en_passant == {?e, 3}
    end

    test "properly clears en_passant field" do
      {:ok, game} =
        Game.new()
        |> Game.move!(Move.from({?d, 2, :P}, {?d, 4}))
        |> Game.move(Move.from({?g, 8, :n}, {?f, 6}))

      assert game.en_passant == nil
    end

    test "updates half_moves properly" do
      {:ok, game} =
        Game.new()
        |> Game.move!(Move.from({?b, 1, :N}, {?c, 3}))
        |> Game.move!(Move.from({?b, 8, :n}, {?c, 6}))
        |> Game.move!(Move.from({?g, 1, :N}, {?f, 3}))
        |> Game.move(Move.from({?g, 8, :n}, {?f, 6}))

      assert game.half_moves == 4
    end

    test "resets half moves when pawn moves" do
      {:ok, game} =
        Game.new()
        |> Game.move!(Move.from({?b, 1, :N}, {?c, 3}))
        |> Game.move!(Move.from({?b, 8, :n}, {?c, 6}))
        |> Game.move!(Move.from({?g, 1, :N}, {?f, 3}))
        |> Game.move!(Move.from({?g, 8, :n}, {?f, 6}))
        |> Game.move(Move.from({?e, 2, :P}, {?e, 4}))

      assert game.half_moves == 0
    end

    test "resets half moves after capture" do
      {:ok, game} =
        Game.new()
        |> Game.move!(Move.from({?b, 1, :N}, {?c, 3}))
        |> Game.move!(Move.from({?b, 8, :n}, {?c, 6}))
        |> Game.move!(Move.from({?c, 3, :N}, {?d, 5}))
        |> Game.move(Move.from({?g, 8, :n}, {?f, 6}))

      assert game.half_moves == 4

      {:ok, game} = Game.move(game, Move.from({?d, 5, :n}, {?f, 6}))

      assert game.half_moves == 0
    end

    test "properly increments full clock after black moves" do
      game = Game.new()
      assert game.full_moves == 1
      {:ok, game} = Game.move(game, Move.from({?e, 2, :P}, {?e, 4}))
      assert game.full_moves == 1
      {:ok, game} = Game.move(game, Move.from({?e, 7, :p}, {?e, 5}))
      assert game.full_moves == 2
      {:ok, game} = Game.move(game, Move.from({?d, 2, :P}, {?d, 4}))
      assert game.full_moves == 2
      {:ok, game} = Game.move(game, Move.from({?e, 5, :p}, {?d, 4}))
      assert game.full_moves == 3
    end

    test "removes castling rights after king moves" do
      {:ok, game} =
        Game.new()
        |> Game.move!(Move.from({?e, 2, :P}, {?e, 3}))
        |> Game.move(Move.from({?e, 7, :p}, {?e, 6}))

      assert game.castling == MapSet.new([:K, :Q, :k, :q])

      {:ok, game} = Game.move(game, Move.from({?e, 1, :K}, {?e, 2}))
      assert game.castling == MapSet.new([:k, :q])

      {:ok, game} = Game.move(game, Move.from({?e, 8, :k}, {?e, 7}))
      assert game.castling == MapSet.new()
    end

    test "remove kingside castling rights after kingside rook moves" do
      {:ok, game} =
        Game.new()
        |> Game.move!(Move.from({?h, 2, :P}, {?h, 3}))
        |> Game.move(Move.from({?h, 7, :p}, {?h, 6}))

      assert game.castling == MapSet.new([:K, :Q, :k, :q])

      {:ok, game} = Game.move(game, Move.from({?h, 1, :R}, {?h, 2}))
      assert game.castling == MapSet.new([:Q, :k, :q])

      {:ok, game} = Game.move(game, Move.from({?h, 8, :r}, {?h, 7}))
      assert game.castling == MapSet.new([:Q, :q])
    end

    test "remove queenside castling rights after queenside rook moves" do
      {:ok, game} =
        Game.new()
        |> Game.move!(Move.from({?a, 2, :P}, {?a, 3}))
        |> Game.move(Move.from({?a, 7, :p}, {?a, 6}))

      assert game.castling == MapSet.new([:K, :Q, :k, :q])

      {:ok, game} = Game.move(game, Move.from({?a, 1, :R}, {?a, 2}))
      assert game.castling == MapSet.new([:K, :k, :q])

      {:ok, game} = Game.move(game, Move.from({?a, 8, :r}, {?a, 7}))
      assert game.castling == MapSet.new([:K, :k])
    end

    test "properly handles moving into and out of check" do
      game = Elchesser.Fen.parse("4K3/7r/8/8/8/8/8/8 b - - 0 1")
      assert game.check == false

      {:ok, game} = Game.move(game, Move.from({?h, 7, :r}, {?h, 8}))
      assert game.check == true

      {:ok, game} = Game.move(game, Move.from({?e, 8, :K}, {?e, 7}))
      assert game.check == false
    end

    test "handles promotion properly" do
      game = Elchesser.Fen.parse("4k3/7P/8/8/8/8/8/8 w - - 0 1")

      {:ok, game} = Game.move(game, Move.from({?h, 7, :P}, {?h, 8}, promotion: :R))
      assert Game.get_square(game, {?h, 8}).piece == :R
      assert game.check == true
    end
  end
end
