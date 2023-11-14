defmodule Elswisser.Pairings.BracketPairingTest do
  use ExUnit.Case, async: true

  alias Elswisser.Tournaments.Tournament
  alias Elswisser.Pairings.BracketPairing

  describe "next_power_of_two/1" do
    test "works as expected for powers of two" do
      assert BracketPairing.next_power_of_two(4) == 4
    end

    test "works as expected for non-powers of two" do
      assert BracketPairing.next_power_of_two(9) == 16
    end
  end

  describe "partition/1" do
    test "works as expected for powers of two" do
      assert BracketPairing.partition([1, 2, 3, 4, 5, 6, 7, 8]) ==
               {[], [1, 2, 3, 4, 5, 6, 7, 8]}
    end

    test "works as expected for non-powers of two" do
      assert BracketPairing.partition([1, 2, 3, 4, 5, 6, 7, 8, 9]) ==
               {[1, 2, 3, 4, 5, 6, 7], [8, 9]}
    end
  end

  describe "rating_based_pairings/1" do
    test "works as expected for powers of two (no byes)" do
      pairings =
        BracketPairing.rating_based_pairings(%Tournament{
          players: [
            %{rating: 800},
            %{rating: 700},
            %{rating: 600},
            %{rating: 500},
            %{rating: 400},
            %{rating: 300},
            %{rating: 200},
            %{rating: 100}
          ]
        })

      assert length(pairings) == 4

      assert Enum.map(pairings, fn p -> {p.player_one.rating, p.player_two.rating} end) == [
               {800, 100},
               {700, 200},
               {600, 300},
               {500, 400}
             ]
    end

    test "works as expected for non-powers of two (with byes)" do
      pairings =
        BracketPairing.rating_based_pairings(%Tournament{
          players: [
            %{rating: 1300},
            %{rating: 1200},
            %{rating: 1100},
            %{rating: 1000},
            %{rating: 900},
            %{rating: 800},
            %{rating: 700},
            %{rating: 600},
            %{rating: 500},
            %{rating: 400},
            %{rating: 300},
            %{rating: 200},
            %{rating: 100}
          ]
        })

      assert Enum.map(pairings, fn p -> {p.player_one.rating, p.player_two.rating} end) == [
               {1300, nil},
               {1200, nil},
               {1100, nil},
               {1000, 100},
               {900, 200},
               {800, 300},
               {700, 400},
               {600, 500}
             ]
    end
  end
end
