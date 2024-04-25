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
end
