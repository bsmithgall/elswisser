defmodule Elswisser.ScoresTest do
  use Elswisser.DataCase

  alias Elswisser.Rounds.Game

  describe "calculate" do
    # set up a tournament with four players and two rounds.
    # black wins every game.
    setup %{} do
      {:ok,
       scores:
         Elswisser.Scores.calculate([
           %{
             game: %Game{
               white: 1,
               black: 2,
               result: -1
             },
             rnd: 1
           },
           %{
             game: %Game{
               white: 3,
               black: 4,
               result: -1
             },
             rnd: 1
           },
           %{
             game: %Game{
               white: 2,
               black: 4,
               result: -1
             },
             rnd: 2
           },
           %{
             game: %Game{
               white: 1,
               black: 3,
               result: -1
             },
             rnd: 2
           }
         ])}
    end

    test "creates an entry in the scores map for each directly", context do
      assert map_size(context[:scores]) == 4
    end

    test "calculates scores for each player correctly", context do
      assert context[:scores][1].score == 0
      assert context[:scores][2].score == 1
      assert context[:scores][3].score == 1
      assert context[:scores][4].score == 2
    end

    test "calculates opponents for each player correctly", context do
      assert context[:scores][1].opponents == [2, 3]
      assert context[:scores][2].opponents == [1, 4]
      assert context[:scores][3].opponents == [4, 1]
      assert context[:scores][4].opponents == [3, 2]
    end

    test "calculate number of black games correctly", context do
      assert context[:scores][1].nblack == 0
      assert context[:scores][2].nblack == 1
      assert context[:scores][3].nblack == 1
      assert context[:scores][4].nblack == 2
    end

    test "calculates cumulative scores correctly", context do
      assert context[:scores][1].cumulative_sum == 0
      assert context[:scores][2].cumulative_sum == 1
      assert context[:scores][3].cumulative_sum == 2
      assert context[:scores][4].cumulative_sum == 3
    end

    test "calculates opposition scores correctly", context do
      # funnily enough, they all end up having three because of the way the
      # fixture is set up
      assert context[:scores][1].cumulative_opp == 3
      assert context[:scores][2].cumulative_opp == 3
      assert context[:scores][3].cumulative_opp == 3
      assert context[:scores][4].cumulative_opp == 3
    end

    test "calculates solkoff score correctly", context do
      # these also all end up with the same score!
      assert context[:scores][1].solkoff == 2
      assert context[:scores][2].solkoff == 2
      assert context[:scores][3].solkoff == 2
      assert context[:scores][4].solkoff == 2
    end
  end
end