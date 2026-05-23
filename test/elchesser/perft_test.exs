defmodule Elchesser.PerftTest do
  use ExUnit.Case

  @moduletag :perft

  alias Elchesser.Fen
  alias Elchesser.Game

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
    if expected > 5_000_000 do
      @tag :slow
    end

    @tag timeout: :infinity
    test "perft(#{depth}, expecting #{expected}) for fen #{fen}" do
      game = Fen.parse(unquote(fen))
      assert perft(game, unquote(depth)) == unquote(expected)
    end
  end

  @spec perft(Game.t(), non_neg_integer()) :: non_neg_integer()
  def perft(_, 0), do: 1

  def perft(game, depth) do
    game
    |> Game.all_legal_moves()
    |> Enum.map(fn move ->
      {:ok, new_game} = Game.make_move(game, move)
      perft(new_game, depth - 1)
    end)
    |> Enum.sum()
  end
end
