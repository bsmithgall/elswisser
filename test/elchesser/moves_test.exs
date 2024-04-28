defmodule Elchesser.MovesTest do
  use ExUnit.Case, async: true

  alias Elchesser.Moves

  describe "generate_move/2 no piece" do
    test "empty board" do
      moves =
        Elchesser.Fen.parse("8/8/8/8/8/8/8/8 w KQkq - 0 1")
        |> Moves.generate_move({?a, 1})

      assert moves == []
    end

    test "full board" do
      moves =
        Elchesser.Fen.parse(
          "ppppppppp/PPPPPPPP/pppppppp/PPPPPPPP/pppppppp/PPP1PPPPP/pppppppp/PPPPPPPP w KQkq - 0 1"
        )
        |> Moves.generate_move({?d, 3})

      assert moves == []
    end
  end

  describe "generate_move/2 rook" do
    test "only rook on board" do
      Elchesser.Fen.parse("8/8/8/8/4R3/8/8/8 w KQkq - 0 1")
      |> Moves.generate_move({?e, 4})
      |> assert_list_eq_any_order([
        {{?f, 4}, false},
        {{?g, 4}, false},
        {{?h, 4}, false},
        {{?a, 4}, false},
        {{?b, 4}, false},
        {{?c, 4}, false},
        {{?d, 4}, false},
        {{?e, 1}, false},
        {{?e, 2}, false},
        {{?e, 3}, false},
        {{?e, 5}, false},
        {{?e, 6}, false},
        {{?e, 7}, false},
        {{?e, 8}, false}
      ])
    end

    test "with interposing pieces" do
      #   ┌───┬───┬───┬───┬───┬───┬───┬───┐
      # 8 │   │   │   │   │   │   │   │   │
      #   ├───┼───┼───┼───┼───┼───┼───┼───┤
      # 7 │   │   │   │   │   │   │   │   │
      #   ├───┼───┼───┼───┼───┼───┼───┼───┤
      # 6 │   │   │   │   │   │   │   │   │
      #   ├───┼───┼───┼───┼───┼───┼───┼───┤
      # 5 │   │   │   │   │   │   │   │   │
      #   ├───┼───┼───┼───┼───┼───┼───┼───┤
      # 4 │   │   │   │   │ ♗ │   │ ♜ │   │
      #   ├───┼───┼───┼───┼───┼───┼───┼───┤
      # 3 │   │   │   │   │   │   │   │   │
      #   ├───┼───┼───┼───┼───┼───┼───┼───┤
      # 2 │   │   │   │   │   │   │   │   │
      #   ├───┼───┼───┼───┼───┼───┼───┼───┤
      # 1 │   │   │   │   │   │   │ ♞ │   │
      #   └───┴───┴───┴───┴───┴───┴───┴───┘
      #     a   b   c   d   e   f   g   h
      Elchesser.Fen.parse("8/8/8/8/4B1r1/8/8/6n1 w KQkq - 0 1")
      |> Moves.generate_move({?g, 4})
      |> assert_list_eq_any_order([
        {{?h, 4}, false},
        {{?e, 4}, true},
        {{?f, 4}, false},
        {{?g, 8}, false},
        {{?g, 7}, false},
        {{?g, 6}, false},
        {{?g, 5}, false},
        {{?g, 3}, false},
        {{?g, 2}, false}
      ])
    end
  end

  describe "generate_move/2 bishop" do
    test "only bishop on board" do
      Elchesser.Fen.parse("8/8/5B2/8/8/8/8/8 w KQkq - 0 1")
      |> Moves.generate_move({?f, 6})
      |> assert_list_eq_any_order([
        {{?g, 5}, false},
        {{?h, 4}, false},
        {{?e, 5}, false},
        {{?d, 4}, false},
        {{?c, 3}, false},
        {{?b, 2}, false},
        {{?a, 1}, false},
        {{?e, 7}, false},
        {{?d, 8}, false},
        {{?g, 7}, false},
        {{?h, 8}, false}
      ])
    end

    test "with interposing pieces" do
      #   ┌───┬───┬───┬───┬───┬───┬───┬───┐
      # 8 │   │   │   │   │   │   │   │ ♖ │
      #   ├───┼───┼───┼───┼───┼───┼───┼───┤
      # 7 │   │   │   │   │   │   │   │   │
      #   ├───┼───┼───┼───┼───┼───┼───┼───┤
      # 6 │   │   │   │   │   │   │   │   │
      #   ├───┼───┼───┼───┼───┼───┼───┼───┤
      # 5 │   │   │   │   │   │   │   │   │
      #   ├───┼───┼───┼───┼───┼───┼───┼───┤
      # 4 │   │   │   │   │   │   │   │   │
      #   ├───┼───┼───┼───┼───┼───┼───┼───┤
      # 3 │ ♞ │   │   │   │   │   │   │   │
      #   ├───┼───┼───┼───┼───┼───┼───┼───┤
      # 2 │   │ ♝ │   │   │   │   │   │   │
      #   ├───┼───┼───┼───┼───┼───┼───┼───┤
      # 1 │   │   │   │   │   │   │   │   │
      #   └───┴───┴───┴───┴───┴───┴───┴───┘
      #     a   b   c   d   e   f   g   h
      Elchesser.Fen.parse("8/6R1/8/8/8/n7/1b6/8 w KQkq - 0 1")
      |> Moves.generate_move({?b, 2})
      |> assert_list_eq_any_order([
        {{?c, 1}, false},
        {{?a, 1}, false},
        {{?c, 3}, false},
        {{?d, 4}, false},
        {{?e, 5}, false},
        {{?f, 6}, false},
        {{?g, 7}, true}
      ])
    end
  end

  describe "generate_move/2 queen" do
    test "only queen on board" do
      Elchesser.Fen.parse("8/8/8/8/8/8/6Q1/8 w KQkq - 0 1")
      |> Moves.generate_move({?g, 2})
      |> assert_list_eq_any_order([
        {{?h, 1}, false},
        {{?f, 1}, false},
        {{?f, 3}, false},
        {{?e, 4}, false},
        {{?d, 5}, false},
        {{?c, 6}, false},
        {{?b, 7}, false},
        {{?a, 8}, false},
        {{?h, 3}, false},
        {{?h, 2}, false},
        {{?a, 2}, false},
        {{?b, 2}, false},
        {{?c, 2}, false},
        {{?d, 2}, false},
        {{?e, 2}, false},
        {{?f, 2}, false},
        {{?g, 1}, false},
        {{?g, 3}, false},
        {{?g, 4}, false},
        {{?g, 5}, false},
        {{?g, 6}, false},
        {{?g, 7}, false},
        {{?g, 8}, false}
      ])
    end

    test "with interposing pieces" do
      #   ┌───┬───┬───┬───┬───┬───┬───┬───┐
      # 8 │   │   │   │   │   │   │   │   │
      #   ├───┼───┼───┼───┼───┼───┼───┼───┤
      # 7 │   │ ♕ │   │   │   │   │   │   │
      #   ├───┼───┼───┼───┼───┼───┼───┼───┤
      # 6 │   │   │   │   │   │   │   │   │
      #   ├───┼───┼───┼───┼───┼───┼───┼───┤
      # 5 │   │   │   │   │   │   │   │   │
      #   ├───┼───┼───┼───┼───┼───┼───┼───┤
      # 4 │   │   │   │   │   │   │ ♖ │   │
      #   ├───┼───┼───┼───┼───┼───┼───┼───┤
      # 3 │   │   │   │   │   │   │   │   │
      #   ├───┼───┼───┼───┼───┼───┼───┼───┤
      # 2 │   │   │   │   │   │ ♝ │ ♛ │   │
      #   ├───┼───┼───┼───┼───┼───┼───┼───┤
      # 1 │   │   │   │   │   │   │   │   │
      #   └───┴───┴───┴───┴───┴───┴───┴───┘
      #     a   b   c   d   e   f   g   h
      Elchesser.Fen.parse("8/1Q6/8/8/6R1/8/5bq1/8 w KQkq - 0 1")
      |> Moves.generate_move({?g, 2})
      |> assert_list_eq_any_order([
        {{?h, 2}, false},
        {{?h, 3}, false},
        {{?h, 1}, false},
        {{?g, 1}, false},
        {{?f, 1}, false},
        {{?g, 3}, false},
        {{?g, 4}, true},
        {{?f, 3}, false},
        {{?e, 4}, false},
        {{?d, 5}, false},
        {{?c, 6}, false},
        {{?b, 7}, true}
      ])
    end
  end

  describe "generate_move/2 knight" do
    test "only knight on the board" do
      Elchesser.Fen.parse("8/8/8/3n4/8/8/8/8 w KQkq - 0 1")
      |> Moves.generate_move({?d, 5})
      |> assert_list_eq_any_order([
        {{?c, 7}, false},
        {{?c, 3}, false},
        {{?b, 6}, false},
        {{?b, 4}, false},
        {{?e, 7}, false},
        {{?e, 3}, false},
        {{?f, 6}, false},
        {{?f, 4}, false}
      ])
    end

    test "knight on the edge of the board" do
      #   ┌───┬───┬───┬───┬───┬───┬───┬───┐
      # 8 │ ♘ │   │   │   │   │   │   │   │
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
      Elchesser.Fen.parse("N7/8/8/8/8/8/8/8 w KQkq - 0 1")
      |> Moves.generate_move({?a, 8})
      |> assert_list_eq_any_order([
        {{?c, 7}, false},
        {{?b, 6}, false}
      ])
    end

    test "with interposing pieces" do
      #   ┌───┬───┬───┬───┬───┬───┬───┬───┐
      # 8 │ ♘ │   │   │   │   │   │   │   │
      #   ├───┼───┼───┼───┼───┼───┼───┼───┤
      # 7 │   │ ♗ │ ♗ │   │   │   │   │   │
      #   ├───┼───┼───┼───┼───┼───┼───┼───┤
      # 6 │ ♟ │ ♟ │ ♟ │ ♟ │   │   │   │   │
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
      Elchesser.Fen.parse("N7/1BB5/pppp4/8/8/8/8/8 w KQkq - 0 1")
      |> Moves.generate_move({?a, 8})
      |> assert_list_eq_any_order([{{?b, 6}, true}])
    end
  end

  describe "generate_move/2 pawn (w)" do
    test "second rank only pawn" do
      Elchesser.Fen.parse("8/8/8/8/8/8/4P3/8 w KQkq - 0 1")
      |> Moves.generate_move({?e, 2})
      |> assert_list_eq_any_order([{{?e, 3}, false}, {{?e, 4}, false}])
    end

    test "third rank only pawn" do
      Elchesser.Fen.parse("8/8/8/8/8/P7/8/8 w KQkq - 0 1")
      |> Moves.generate_move({?a, 3})
      |> assert_list_eq_any_order([{{?a, 4}, false}])
    end

    test "second rank with captures" do
      Elchesser.Fen.parse("8/8/8/8/8/5p2/4P3/8 w KQkq - 0 1")
      |> Moves.generate_move({?e, 2})
      |> assert_list_eq_any_order([{{?e, 3}, false}, {{?e, 4}, false}, {{?f, 3}, true}])
    end

    test "third rank with captures" do
      Elchesser.Fen.parse("8/8/8/8/pp5p/P7/8/8 w KQkq - 0 1")
      |> Moves.generate_move({?a, 3})
      |> assert_list_eq_any_order([{{?b, 4}, true}])
    end

    test "en-passant" do
      Elchesser.Fen.parse("rnbqkbnr/ppp1p1pp/8/3pPp2/8/8/PPPP1PPP/RNBQKBNR w KQkq f6 0 2")
      |> Moves.generate_move({?e, 5})
      |> assert_list_eq_any_order([{{?e, 6}, false}, {{?f, 6}, true}])
    end
  end

  describe "generate_move/2 pawn (b)" do
    test "seventh rank only pawn" do
      Elchesser.Fen.parse("8/4p3/8/8/8/8/8/8 w KQkq - 0 1")
      |> Moves.generate_move({?e, 7})
      |> assert_list_eq_any_order([{{?e, 6}, false}, {{?e, 5}, false}])
    end

    test "sixth rank only pawn" do
      Elchesser.Fen.parse("8/8/7p/8/8/8/8/8 w KQkq - 0 1")
      |> Moves.generate_move({?h, 6})
      |> assert_list_eq_any_order([{{?h, 5}, false}])
    end

    test "seventh rank with captures" do
      Elchesser.Fen.parse("8/4p3/5P2/8/8/8/8/8 w KQkq - 0 1")
      |> Moves.generate_move({?e, 7})
      |> assert_list_eq_any_order([{{?e, 6}, false}, {{?e, 5}, false}, {{?f, 6}, true}])
    end

    test "sixth rank with captures" do
      Elchesser.Fen.parse("8/8/7p/PPPPPPPP/8/8/8/8 w KQkq - 0 1")
      |> Moves.generate_move({?h, 6})
      |> assert_list_eq_any_order([{{?g, 5}, true}])
    end

    test "en-passant" do
      Elchesser.Fen.parse("rnbqkbnr/pppp1ppp/8/8/3PpP2/8/PPP1P1PP/RNBQKBNR w KQkq d3 0 2")
      |> Moves.generate_move({?e, 4})
      |> assert_list_eq_any_order([{{?e, 3}, false}, {{?d, 3}, true}])
    end
  end

  def assert_list_eq_any_order(left, right) when is_list(left) and is_list(right) do
    assert Enum.sort(left) == Enum.sort(right)
  end
end
