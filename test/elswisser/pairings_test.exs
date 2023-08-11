defmodule Elswisser.PairingsTest do
  use Elswisser.DataCase

  alias Elswisser.Pairings.Pairing
  alias Elswisser.Pairings.PairWeight
  alias Elswisser.Pairings.Worker

  import Elswisser.ScoresFixtures

  describe "first round partition" do
    setup %{} do
      {:ok,
       partition:
         scores_fixture_with_players_first_round()
         |> Elswisser.Scores.sort()
         |> Pairing.partition()}
    end

    test "top rated player in top half at half_idx 0", %{partition: partition} do
      player = Enum.at(partition, 0)

      assert player.score.rating == 800
      assert player.upperhalf == true
      assert player.half_idx == 0
    end

    test "bottom rated player in bottom half at half_idx 3", %{partition: partition} do
      player = Enum.at(partition, 7)

      assert player.score.rating == 100
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

    test "cartesian_product creates the correct number of outcomes", %{partition: partition} do
      # number of unqiue pairs
      assert length(Pairing.cartesian_product(partition)) ==
               length(partition) * (length(partition) - 1) / 2
    end
  end

  describe "in-progress tournament partition" do
    setup %{} do
      {:ok,
       partition:
         scores_fixture_with_players()
         |> Elswisser.Scores.sort()
         |> Pairing.partition()}
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

    test "cartesian_product creates the correct number of outcomes", %{partition: partition} do
      # number of unqiue pairs
      assert length(Pairing.cartesian_product(partition)) ==
               length(partition) * (length(partition) - 1) / 2
    end
  end

  test "max_score works as expected" do
    assert scores_fixture() |> Map.values() |> Pairing.max_score() == 3
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
        |> Pairing.pair()

      assert Worker.direct_call(pid, first_round) == {:ok, [{5, 1}, {6, 2}, {7, 3}, {8, 4}]}
    end
  end

  defp start_worker(_) do
    {:ok, pid} = Worker.start_link()
    %{pid: pid}
  end
end
