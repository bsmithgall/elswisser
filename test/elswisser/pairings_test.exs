defmodule Elswisser.PairingsTest do
  use Elswisser.DataCase

  alias Elswisser.Pairings
  alias Elswisser.Pairings.PairWeight
  alias Elswisser.Pairings.Worker

  import Elswisser.ScoresFixtures

  describe "first round partition" do
    setup %{} do
      {:ok,
       partition:
         scores_fixture_with_players_first_round()
         |> Elswisser.Scores.sort()
         |> Pairings.partition()}
    end

    test "top rated player in top half at half_idx 0", %{partition: partition} do
      player = Enum.at(partition, 0)

      assert player.score.player.rating == 800
      assert player.upperhalf == true
      assert player.half_idx == 0
    end

    test "bottom rated player in bottom half at half_idx 3", %{partition: partition} do
      player = Enum.at(partition, 7)

      assert player.score.player.rating == 100
      assert player.upperhalf == false
      assert player.half_idx == 3
    end

    test "pair scoring puts idx 0 and idx 5 > idx 0 and idx 1", %{partition: partition} do
      assert PairWeight.score(Enum.at(partition, 0), Enum.at(partition, 5)) >
               PairWeight.score(Enum.at(partition, 0), Enum.at(partition, 1))
    end

    test "pair scoring puts idx 0 and idx 5 > idx 0 and idx 6", %{partition: partition} do
      assert PairWeight.score(Enum.at(partition, 0), Enum.at(partition, 5)) >
               PairWeight.score(Enum.at(partition, 0), Enum.at(partition, 6))
    end

    test "unique_possible_pairs creates the correct number of outcomes", %{partition: partition} do
      # number of unqiue pairs
      assert length(Pairings.unique_possible_pairs(partition)) ==
               length(partition) * (length(partition) - 1) / 2
    end
  end

  describe "in-progress tournament partition" do
    setup %{} do
      {:ok,
       partition:
         scores_fixture_with_players()
         |> Elswisser.Scores.sort()
         |> Pairings.partition()}
    end

    test "top scoring player in top half at half_idx 0", %{partition: partition} do
      player = Enum.at(partition, 0)

      assert player.score.score == 3
      assert player.upperhalf == true
      assert player.half_idx == 0
    end

    test "bottom scoring player in bottom half at half_idx 3", %{partition: partition} do
      player = Enum.at(partition, 7)

      assert player.score.score == 0
      assert player.upperhalf == false
      assert player.half_idx == 3
    end

    test "pair scoring works as expected", %{partition: partition} do
      assert is_number(PairWeight.score(Enum.at(partition, 0), Enum.at(partition, 5), 3))
    end

    test "unique_possible_pairs creates the correct number of outcomes", %{partition: partition} do
      # number of unqiue pairs
      assert length(Pairings.unique_possible_pairs(partition)) ==
               length(partition) * (length(partition) - 1) / 2
    end
  end

  test "max_score works as expected" do
    assert scores_fixture() |> Map.values() |> Pairings.max_score() == 3
  end

  describe "pairing via matching worker algorithm" do
    setup :start_worker

    test "empty graph works as expected", %{pid: pid} do
      assert Worker.direct_call(pid, []) == {:ok, []}
    end

    test "simple graph works as expected", %{pid: pid} do
      assert Worker.direct_call(pid, [{1, 2, 3.1415}, {2, 3, 2.7183}, {1, 3, 3.0}, {1, 4, 1.4142}]) ==
               {:ok, [{2, 3}, {1, 4}]}
    end

    test "first round with known ratings matches as expected", %{pid: pid} do
      first_round =
        scores_fixture_with_players_first_round()
        |> Elswisser.Scores.sort()
        |> Pairings.partition()
        |> Pairings.unique_possible_pairs()

      assert Worker.direct_call(pid, first_round) == {:ok, [{4, 0}, {5, 1}, {6, 2}, {7, 3}]}
    end
  end

  describe "#assign_colors" do
    test "left more black games than right" do
      assert Pairings.assign_colors([{1, 2}], %{
               1 => %{nblack: 10},
               2 => %{nblack: 5}
             }) == [{1, 2}]
    end

    test "right more black games than left" do
      assert Pairings.assign_colors([{1, 2}], %{
               1 => %{nblack: 5},
               2 => %{nblack: 10}
             }) == [{2, 1}]
    end

    test "same black games, but left was last white and right was not" do
      assert Pairings.assign_colors([{1, 2}], %{
               1 => %{nblack: 2, lastwhite: true},
               2 => %{nblack: 2, lastwhite: false}
             }) == [{2, 1}]
    end

    test "same black games, but right was last white and left was not" do
      assert Pairings.assign_colors([{1, 2}], %{
               1 => %{nblack: 2, lastwhite: false},
               2 => %{nblack: 2, lastwhite: true}
             }) == [{1, 2}]
    end

    test "everything the same" do
      assert Pairings.assign_colors([{1, 2}], %{
               1 => %{nblack: 2, lastwhite: true},
               2 => %{nblack: 2, lastwhite: true}
             }) == [{1, 2}]
    end
  end

  describe "#assign_bye_player" do
    setup %{} do
      {:ok,
       scores:
         scores_fixture_with_players_first_round()
         |> Elswisser.Scores.sort()}
    end

    test "returns {:none, input} when passed with an even list", %{scores: scores} do
      assert Pairings.assign_bye_player(scores) == {:none, scores}
    end

    test "returns the bye player correctly when passed with an odd list", %{scores: scores} do
      scores = Enum.take(scores, 7)

      assert Pairings.assign_bye_player(scores) == {Enum.at(scores, -1), Enum.take(scores, 6)}
    end
  end

  defp start_worker(_) do
    {:ok, pid} = Worker.start_link()
    %{pid: pid}
  end
end
