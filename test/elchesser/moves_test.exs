defmodule Elchesser.MovesTest do
  use ExUnit.Case, async: true

  alias Elchesser.Move

  describe "generate_move/2 no piece" do
    test "empty board" do
      moves =
        Elchesser.Fen.parse("8/8/8/8/8/8/8/8 w KQkq - 0 1")
        |> Move.generate_move({?a, 1})

      assert moves == []
    end

    test "full board" do
      moves =
        Elchesser.Fen.parse(
          "ppppppppp/PPPPPPPP/pppppppp/PPPPPPPP/pppppppp/PPP1PPPPP/pppppppp/PPPPPPPP w KQkq - 0 1"
        )
        |> Move.generate_move({?d, 3})

      assert moves == []
    end
  end
end
