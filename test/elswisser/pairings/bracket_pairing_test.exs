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
               {500, 400},
               {600, 300},
               {700, 200}
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
    end
  end
end
