defmodule Elswisser.Pairings.BracketTest do
  use ExUnit.Case, async: true

  alias Elswisser.Pairings.Bye
  alias Elswisser.Tournaments.Tournament
  alias Elswisser.Pairings.Bracket

  describe "next_power_of_two/1" do
    test "works as expected for powers of two" do
      assert Bracket.next_power_of_two(4) == 4
    end

    test "works as expected for non-powers of two" do
      assert Bracket.next_power_of_two(9) == 16
    end
  end

  describe "partition/1" do
    test "works as expected for powers of two" do
      assert Bracket.partition([1, 2, 3, 4, 5, 6, 7, 8]) ==
               {[], [1, 2, 3, 4, 5, 6, 7, 8]}
    end

    test "works as expected for non-powers of two" do
      assert Bracket.partition([1, 2, 3, 4, 5, 6, 7, 8, 9]) ==
               {[1, 2, 3, 4, 5, 6, 7], [8, 9]}
    end
  end

  describe "rating_based_pairings/1" do
    test "works as expected for powers of two (no byes)" do
      pairings =
        Bracket.rating_based_pairings(%Tournament{
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

      assert pairings == [
               {%{rating: 800}, %{rating: 100}},
               {%{rating: 700}, %{rating: 200}},
               {%{rating: 600}, %{rating: 300}},
               {%{rating: 500}, %{rating: 400}}
             ]
    end

    test "works as expected for non-powers of two (with byes)" do
      pairings =
        Bracket.rating_based_pairings(%Tournament{
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

      assert pairings == [
               {%{rating: 1300}, Bye.bye_player()},
               {%{rating: 1200}, Bye.bye_player()},
               {%{rating: 1100}, Bye.bye_player()},
               {%{rating: 1000}, %{rating: 100}},
               {%{rating: 900}, %{rating: 200}},
               {%{rating: 800}, %{rating: 300}},
               {%{rating: 700}, %{rating: 400}},
               {%{rating: 600}, %{rating: 500}}
             ]
    end
  end
end
