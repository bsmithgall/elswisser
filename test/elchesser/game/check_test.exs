defmodule Elchesser.Game.CheckTest do
  alias Elchesser.Game.Check
  use ExUnit.Case, async: true

  test "white pieces in check" do
    assert Elchesser.Fen.parse("4K2r/8/8/8/8/8/8/8 w k - 0 1")
           |> Check.check?(:w) == true
  end

  test "white pieces not in check" do
    assert Elchesser.Fen.parse("4K2R/8/8/8/8/8/8/8 w k - 0 1")
           |> Check.check?(:w) == false
  end

  test "black pieces in check" do
    assert Elchesser.Fen.parse("4k2R/8/8/8/8/8/8/8 w k - 0 1")
           |> Check.check?(:b) == true
  end

  test "black pieces not in check" do
    assert Elchesser.Fen.parse("4k2r/8/8/8/8/8/8/8 w k - 0 1")
           |> Check.check?(:b) == false
  end
end
