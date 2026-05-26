defmodule Elchesser.Game.CastlingTest do
  use ExUnit.Case, async: true

  alias Elchesser.{Game, Move}

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

  test "remove queenside castling rights after queenside rook is captured (black)" do
    game = Elchesser.Fen.parse("r3k2r/pppppppp/8/8/8/7P/1bPPPPP1/RNBQKBNR b KQkq - 0 1")

    assert game.castling == MapSet.new([:K, :Q, :k, :q])

    {:ok, game} = Game.move(game, Move.from({?b, 2, :b}, {?a, 1}))
    refute MapSet.member?(game.castling, :Q)
  end

  test "remove queenside castling rights after rook is captured (white)" do
    game = Elchesser.Fen.parse("rnbqkbnr/pBppppp1/7p/8/8/8/PPPPPPPP/RNBQK1NR w KQkq - 0 1")

    assert game.castling == MapSet.new([:K, :Q, :k, :q])

    {:ok, game} = Game.move(game, Move.from({?b, 7, :b}, {?a, 8}))
    refute MapSet.member?(game.castling, :q)
  end

  test "remove kingside castling rights after rook is captured (black)" do
    game = Elchesser.Fen.parse("rn1qkbnr/pppppppp/8/8/8/P7/1PPPPPbP/RNBQKBNR b KQkq - 0 1")
    assert game.castling == MapSet.new([:K, :Q, :k, :q])

    {:ok, game} = Game.move(game, Move.from({?g, 2, :b}, {?h, 1}))
    refute MapSet.member?(game.castling, :K)
  end

  test "remove kingside castling rights after rook is captured (white)" do
    game = Elchesser.Fen.parse("rnbqkbnr/ppppppBp/8/8/8/8/PPPPPPPP/RN1QKBNR w KQkq - 0 1")
    assert game.castling == MapSet.new([:K, :Q, :k, :q])

    {:ok, game} = Game.move(game, Move.from({?g, 7, :b}, {?h, 8}))
    refute MapSet.member?(game.castling, :k)
  end
end
