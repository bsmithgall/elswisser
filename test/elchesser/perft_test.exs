defmodule Elchesser.PerftTest do
  use ExUnit.Case

  @moduletag :perft

  alias Elchesser.Fen
  alias Elchesser.Perft

  @perft_fixtures Path.join([File.cwd!(), "test", "support", "fixtures", "perft.epd"])
                  |> Path.expand()
                  |> File.read!()
                  |> String.trim()
                  |> String.split("\n")
                  |> Enum.map(&String.split(&1, ";"))
                  |> Enum.map(fn [fen | positions] ->
                    positions
                    |> Enum.map(&String.split(&1, " "))
                    |> Enum.map(fn ["D" <> d, pos] ->
                      {String.to_integer(d), String.to_integer(pos)}
                    end)
                    |> then(fn pos -> {fen, pos} end)
                  end)

  for {fen, depths} <- @perft_fixtures, {depth, expected} <- depths do
    @tag slow: expected > 5_000_000
    @tag timeout: :infinity
    test "perft(#{depth}, expecting #{expected}) for fen #{fen}" do
      game = Fen.parse(unquote(fen))
      assert Perft.perft(game, unquote(depth)) == unquote(expected)
    end
  end
end
