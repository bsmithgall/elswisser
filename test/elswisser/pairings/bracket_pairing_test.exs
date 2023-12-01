defmodule Elswisser.Pairings.BracketPairingTest do
  use ExUnit.Case, async: true

  alias Elswisser.Tournaments.Tournament
  alias Elswisser.Players.Player
  alias Elswisser.Pairings.BracketPairing

  describe "next_power_of_two/1" do
    test "works as expected for powers of two" do
      assert BracketPairing.next_power_of_two(4) == 4
    end

    test "works as expected for non-powers of two" do
      assert BracketPairing.next_power_of_two(9) == 16
    end
  end

  describe "rating_based_pairings/1" do
    test "works as expected for powers of two (no byes)" do
      pairings =
        BracketPairing.rating_based_pairings(%Tournament{
          players: [
            %Player{rating: 800},
            %Player{rating: 700},
            %Player{rating: 600},
            %Player{rating: 500},
            %Player{rating: 400},
            %Player{rating: 300},
            %Player{rating: 200},
            %Player{rating: 100}
          ]
        })

      assert length(pairings) == 4

      assert Enum.map(pairings, fn p -> {p.player_one.rating, p.player_two.rating} end) == [
               {800, 100},
               {500, 400},
               {600, 300},
               {700, 200}
             ]

      assert Enum.map(pairings, &{&1.player_one_seed, &1.player_two_seed}) == [
               {1, 8},
               {4, 5},
               {3, 6},
               {2, 7}
             ]
    end

    test "works as expected for non-powers of two (with byes)" do
      pairings =
        BracketPairing.rating_based_pairings(%Tournament{
          players: [
            %Player{rating: 1300},
            %Player{rating: 1200},
            %Player{rating: 1100},
            %Player{rating: 1000},
            %Player{rating: 900},
            %Player{rating: 800},
            %Player{rating: 700},
            %Player{rating: 600},
            %Player{rating: 500},
            %Player{rating: 400},
            %Player{rating: 300},
            %Player{rating: 200},
            %Player{rating: 100}
          ]
        })

      assert length(pairings) == 8

      assert Enum.map(pairings, &{&1.player_one.rating, &1.player_two.rating}) == [
               {1300, nil},
               {600, 500},
               {900, 200},
               {1000, 100},
               {1100, nil},
               {800, 300},
               {700, 400},
               {1200, nil}
             ]

      assert Enum.map(pairings, &{&1.player_one_seed, &1.player_two_seed}) == [
               {1, nil},
               {8, 9},
               {5, 12},
               {4, 13},
               {3, nil},
               {6, 11},
               {7, 10},
               {2, nil}
             ]
    end
  end
end
