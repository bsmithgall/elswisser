defmodule Elchesser.MoveTest do
  use ExUnit.Case, async: true

  alias Elchesser.Move

  describe "as_san/2" do
    test "standard pawn moves work as expected" do
      assert Move.from({?e, 2}, {?e, 4}) |> Move.as_san(:p) == "e4"
    end

    test "standard piece moves work as expected" do
      assert Move.from({?e, 2}, {?e, 4}) |> Move.as_san(:q) == "Qe4"
    end

    test "pawn captures work as expected" do
      assert Move.from({?e, 4}, {?d, 5}, capture: true) |> Move.as_san(:p) == "exd5"
    end

    test "piece captures work as expected" do
      assert Move.from({?e, 2}, {?e, 4}, capture: true) |> Move.as_san(:q) == "Qxe4"
    end

    test "castle kingside works as expected" do
      assert Move.from({?e, 1}, {?g, 1}, castle: true) |> Move.as_san(:k) == "O-O"
    end

    test "castle queenside works as expected" do
      assert Move.from({?e, 8}, {?c, 8}, castle: true) |> Move.as_san(:K) == "O-O-O"
    end

    test "normal promotion works as expected" do
      assert Move.from({?a, 7}, {?a, 8}, promotion: :n) |> Move.as_san(:p) == "a8=N"
    end

    test "capture promotion works as expected" do
      assert Move.from({?c, 2}, {?d, 1}, promotion: :Q, capture: true) |> Move.as_san(:P) ==
               "cxd1=Q"
    end

    test "check works as expected" do
      assert Move.from({?h, 5}, {?f, 7}, capture: true) |> Move.as_san(:q, :check) == "Qxf7+"
    end

    test "checkmate works as expected" do
      assert Move.from({?h, 5}, {?f, 7}, capture: true) |> Move.as_san(:q, :checkmate) == "Qxf7#"
    end

    test "stalemate works as expected" do
      assert Move.from({?d, 6}, {?d, 7}) |> Move.as_san(:p, :stalemate) == "d7="
    end
  end
end
