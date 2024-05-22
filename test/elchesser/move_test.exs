defmodule Elchesser.MoveTest do
  use ExUnit.Case, async: true

  alias Elchesser.Move

  describe "as_san/2" do
    test "standard pawn moves work as expected" do
      assert Move.from({?e, 2, :P}, {?e, 4}) |> Move.as_san() == "e4"
    end

    test "standard piece moves work as expected" do
      assert Move.from({?e, 2, :q}, {?e, 4}) |> Move.as_san() == "Qe4"
    end

    test "pawn captures work as expected" do
      assert Move.from({?e, 4, :p}, {?d, 5}, capture: true) |> Move.as_san() == "exd5"
    end

    test "piece captures work as expected" do
      assert Move.from({?e, 2, :q}, {?e, 4}, capture: true) |> Move.as_san() == "Qxe4"
    end

    test "castle kingside works as expected" do
      assert Move.from({?e, 1, :k}, {?g, 1}, castle: true) |> Move.as_san() == "O-O"
    end

    test "castle queenside works as expected" do
      assert Move.from({?e, 8, :K}, {?c, 8}, castle: true) |> Move.as_san() == "O-O-O"
    end

    test "normal promotion works as expected" do
      assert Move.from({?a, 7, :p}, {?a, 8}, promotion: :n) |> Move.as_san() == "a8=N"
    end

    test "capture promotion works as expected" do
      assert Move.from({?c, 2, :P}, {?d, 1}, promotion: :Q, capture: true) |> Move.as_san() ==
               "cxd1=Q"
    end

    test "check works as expected" do
      assert Move.from({?h, 5, :q}, {?f, 7}, capture: true, checking: :check)
             |> Move.as_san(:check) == "Qxf7+"
    end

    test "checkmate works as expected" do
      assert Move.from({?h, 5, :Q}, {?f, 7}, capture: true, checking: :checkmate)
             |> Move.as_san(:checkmate) == "Qxf7#"
    end

    test "stalemate works as expected" do
      assert Move.from({?d, 6, :p}, {?d, 7}) |> Move.as_san(:stalemate) == "d7="
    end
  end
end
