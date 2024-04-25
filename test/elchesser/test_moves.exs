defmodule Elchesser.MovesTest do
  use ExUnit.Case, async: true

  alias Elchesser.Moves

  describe "generate_moves/3 rook" do
    test "only rook on board" do
      game = Elchesser.Fen.parse("8/8/8/8/4R3/8/8/8 w KQkq - 0 1")

      moves = Moves.generate_moves(game)

      assert Map.get(moves, {?a, 1}) == [
               {?a, 4},
               {?b, 4},
               {?c, 4},
               {?d, 4},
               {?f, 4},
               {?g, 4},
               {?h, 4},
               {?e, 1},
               {?e, 2},
               {?e, 3},
               {?e, 5},
               {?e, 6},
               {?e, 7},
               {?e, 8}
             ]
    end

    test "with friendly pieces" do
    end

    test "with enemy pieces" do
    end
  end

  describe "generate_moves/3 bishop" do
    test "only bishop on board" do
    end

    test "with friendly pieces" do
    end

    test "with enemy pieces" do
    end
  end

  describe "generate_moves/3 queen" do
    test "only queen on board" do
    end

    test "with friendly pieces" do
    end

    test "with enemy pieces" do
    end
  end
end
