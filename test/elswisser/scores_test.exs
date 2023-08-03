defmodule Elswisser.ScoresTest do
  use Elswisser.DataCase

  describe "calculate" do
    import Elswisser.ScoresFixtures

    setup %{} do
      {:ok, scores: scores_fixture()}
    end

    test "creates an entry in the scores map for each directly", context do
      assert map_size(context[:scores]) == 8
    end

    test "calculates scores for each player correctly", context do
      assert context[:scores][1].score == 1
      assert context[:scores][2].score == 2
      assert context[:scores][3].score == 1
      assert context[:scores][4].score == 2
      assert context[:scores][5].score == 1
      assert context[:scores][6].score == 0
      assert context[:scores][7].score == 3
      assert context[:scores][8].score == 2
    end

    test "calculates opponents for each player correctly", context do
      assert context[:scores][1].opponents == [4, 2, 8]
      assert context[:scores][2].opponents == [3, 1, 7]
      assert context[:scores][3].opponents == [2, 6, 4]
      assert context[:scores][4].opponents == [1, 5, 3]
      assert context[:scores][5].opponents == [7, 4, 6]
      assert context[:scores][6].opponents == [8, 3, 5]
      assert context[:scores][7].opponents == [5, 8, 2]
      assert context[:scores][8].opponents == [6, 7, 1]
    end

    test "calculate number of black games correctly", context do
      assert context[:scores][1].nblack == 2
      assert context[:scores][2].nblack == 2
      assert context[:scores][3].nblack == 2
      assert context[:scores][4].nblack == 1
      assert context[:scores][5].nblack == 2
      assert context[:scores][6].nblack == 1
      assert context[:scores][7].nblack == 1
      assert context[:scores][8].nblack == 1
    end

    test "calculates cumulative scores correctly", context do
      assert context[:scores][1].cumulative_sum == 1
      assert context[:scores][2].cumulative_sum == 3
      assert context[:scores][3].cumulative_sum == 2
      assert context[:scores][4].cumulative_sum == 5
      assert context[:scores][5].cumulative_sum == 3
      assert context[:scores][6].cumulative_sum == 0
      assert context[:scores][7].cumulative_sum == 6
      assert context[:scores][8].cumulative_sum == 4
    end

    test "calculates opposition scores correctly", context do
      assert context[:scores][1].cumulative_opp == 12
      assert context[:scores][2].cumulative_opp == 9
      assert context[:scores][3].cumulative_opp == 8
      assert context[:scores][4].cumulative_opp == 6
      assert context[:scores][5].cumulative_opp == 11
      assert context[:scores][6].cumulative_opp == 9
      assert context[:scores][7].cumulative_opp == 10
      assert context[:scores][8].cumulative_opp == 7
    end

    test "calculates solkoff score correctly", context do
      assert context[:scores][1].solkoff == 6
      assert context[:scores][2].solkoff == 5
      assert context[:scores][3].solkoff == 4
      assert context[:scores][4].solkoff == 3
      assert context[:scores][5].solkoff == 5
      assert context[:scores][6].solkoff == 4
      assert context[:scores][7].solkoff == 5
      assert context[:scores][8].solkoff == 4
    end

    test "calculates modified median correctly", context do
      assert context[:scores][1].modmed == 4
      assert context[:scores][2].modmed == 4
      assert context[:scores][3].modmed == 2
      assert context[:scores][4].modmed == 2
      assert context[:scores][5].modmed == 2
      assert context[:scores][6].modmed == 2
      assert context[:scores][7].modmed == 4
      assert context[:scores][8].modmed == 4
    end
  end
end
