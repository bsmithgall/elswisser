defmodule Elswisser.Pairings.RoundRobinTest do
  alias Elswisser.Pairings.RoundRobin
  use ExUnit.Case, async: true

  describe "make_pairings/1" do
    test "makes the correct number of games with an even number of players" do
      players = [1, 2, 3, 4, 5, 6]
      pairings = RoundRobin.make_pairings(players)

      assert Enum.map(pairings, &Kernel.length/1) |> Enum.sum() == 3 * 5
    end

    test "makes the correct number of games with an odd number of players" do
      players = [1, 2, 3, 4, 5]
      pairings = RoundRobin.make_pairings(players)

      assert Enum.map(pairings, &Kernel.length/1) |> Enum.sum() == 3 * 5
    end

    test "balances the players as best as possible" do
      players = [1, 2, 3, 4, 5, 6, 7, 8]
      pairings = RoundRobin.make_pairings(players)

      # count the number of times each player appears in white (0 idx) or black
      # (1 idx)
      counts =
        pairings
        |> List.flatten()
        |> Enum.map(&Tuple.to_list/1)
        |> Enum.map(&Enum.with_index/1)
        |> List.flatten()
        |> Enum.frequencies()

      assert Map.values(counts) |> Enum.min_max() == {3, 4}
    end
  end
end
