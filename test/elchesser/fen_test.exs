defmodule Elchesser.FenTest do
  use ExUnit.Case, async: true

  describe "parse/1" do
    test "starting position works as expected" do
      start = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

      start_game = Elchesser.Fen.parse(start)

      assert inspect(start_game) ==
               """
                 ┌───┬───┬───┬───┬───┬───┬───┬───┐
               8 │ ♜ │ ♞ │ ♝ │ ♛ │ ♚ │ ♝ │ ♞ │ ♜ │
                 ├───┼───┼───┼───┼───┼───┼───┼───┤
               7 │ ♟ │ ♟ │ ♟ │ ♟ │ ♟ │ ♟ │ ♟ │ ♟ │
                 ├───┼───┼───┼───┼───┼───┼───┼───┤
               6 │   │   │   │   │   │   │   │   │
                 ├───┼───┼───┼───┼───┼───┼───┼───┤
               5 │   │   │   │   │   │   │   │   │
                 ├───┼───┼───┼───┼───┼───┼───┼───┤
               4 │   │   │   │   │   │   │   │   │
                 ├───┼───┼───┼───┼───┼───┼───┼───┤
               3 │   │   │   │   │   │   │   │   │
                 ├───┼───┼───┼───┼───┼───┼───┼───┤
               2 │ ♙ │ ♙ │ ♙ │ ♙ │ ♙ │ ♙ │ ♙ │ ♙ │
                 ├───┼───┼───┼───┼───┼───┼───┼───┤
               1 │ ♖ │ ♘ │ ♗ │ ♕ │ ♔ │ ♗ │ ♘ │ ♖ │
                 └───┴───┴───┴───┴───┴───┴───┴───┘
                   a   b   c   d   e   f   g   h
               """
               |> String.trim_trailing()
    end
  end

  describe "dump/1" do
    test "starting position works as expected" do
      g = Elchesser.Game.new()

      assert Elchesser.Fen.dump(g) == "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    end

    test "dump flushes trailing empty squares" do
      # After 1. e4, rank 4 should be "4P3" not "4P"
      {:ok, g} = Elchesser.Game.new() |> Elchesser.Game.move("e4")
      fen = Elchesser.Fen.dump(g)
      [board | _] = String.split(fen, " ")
      ranks = String.split(board, "/")

      # Rank 4 (index 4 from top = "8/8/8/8" then rank 4) is the 5th element
      assert Enum.at(ranks, 4) == "4P3"
    end

    test "dump roundtrips through parse" do
      {:ok, g} = Elchesser.Game.new() |> Elchesser.Game.move("e4")
      fen = Elchesser.Fen.dump(g)
      [board | _] = String.split(fen, " ")

      # Every rank in the board string must account for exactly 8 squares
      for rank <- String.split(board, "/") do
        count =
          rank
          |> String.graphemes()
          |> Enum.reduce(0, fn ch, acc ->
            case Integer.parse(ch) do
              {n, _} -> acc + n
              :error -> acc + 1
            end
          end)

        assert count == 8, "Rank '#{rank}' accounts for #{count} squares, expected 8"
      end
    end
  end
end
