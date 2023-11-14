defmodule Elswisser.TournamentsTest do
  alias Elswisser.Rounds
  alias Elswisser.Tournaments.Tournament
  use Elswisser.DataCase

  alias Elswisser.Tournaments

  describe "tournaments" do
    alias Elswisser.Tournaments.Tournament
    import Elswisser.TournamentsFixtures

    @invalid_attrs %{name: nil}

    test "list_tournaments/0 returns all tournaments" do
      tournament = tournament_fixture()
      assert Tournaments.list_tournaments() == [tournament]
    end

    test "get_tournament!/1 returns the tournament with given id" do
      tournament = tournament_fixture()
      assert Tournaments.get_tournament!(tournament.id) == tournament
    end

    test "create_tournament/1 with valid data creates a tournament" do
      valid_attrs = %{name: "some name", type: :swiss}

      assert {:ok, %Tournament{} = tournament} = Tournaments.create_tournament(valid_attrs)
      assert tournament.name == "some name"
    end

    test "create_tournament/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tournaments.create_tournament(@invalid_attrs)
    end

    test "delete_tournament/1 deletes the tournament" do
      tournament = tournament_fixture()
      assert {:ok, %Tournament{}} = Tournaments.delete_tournament(tournament)
      assert_raise Ecto.NoResultsError, fn -> Tournaments.get_tournament!(tournament.id) end
    end
  end

  describe "rosters" do
    import Elswisser.TournamentsFixtures
    import Elswisser.PlayersFixtures

    test "get_roster/1 with null returns all false" do
      _tournament = tournament_with_players_fixture()
      {in_, out_} = Tournaments.get_roster(nil)

      assert(length(in_) == 0)

      assert(
        out_,
        Enum.map(Elswisser.Players.list_players(), fn p ->
          Map.merge(p, %{in_tournament: false})
        end)
      )
    end

    test "get_roster/1 with tournament_id returns correct mapping" do
      tournament = tournament_with_players_fixture()
      not_in_tournament = player_fixture()
      {in_, out_} = Tournaments.get_roster(tournament.id)

      assert(
        in_ == Enum.map(tournament.players, fn p -> Map.merge(p, %{in_tournament: true}) end)
      )

      assert(out_ == [Map.merge(not_in_tournament, %{in_tournament: false})])
    end
  end

  describe "calculate_length" do
    test "calculate_length/2 with nils returns 0" do
      assert Tournaments.calculate_length(nil, nil) == 0
    end

    test "calculate_length/2 with empty players returns 0" do
      assert Tournaments.calculate_length([], nil) == 0
    end

    test "calculate_length/2 works as expected for swiss tournaments" do
      assert Tournaments.calculate_length(
               [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17],
               :swiss
             ) == 5
    end

    test "calculate_length/2 works as expected for single_elimination tournaments" do
      assert Tournaments.calculate_length(
               [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17],
               :single_elimination
             ) == 5
    end

    test "calculate_length/2 works as expected for double_elimination tournaments" do
      assert Tournaments.calculate_length(
               [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17],
               :double_elimination
             ) == 9
    end
  end

  describe "create_next_round/2" do
    import Elswisser.TournamentsFixtures

    test "works as expected for creating rounds past the end of the tournament" do
      assert Tournaments.create_next_round(%Tournament{length: 4}, 6) == :finished
    end

    test "works as expected for creating a random swiss round" do
      tournament = tournament_fixture(%{length: 2})
      {:ok, rnd} = Tournaments.create_next_round(tournament, 0)

      assert rnd.number == 1
    end

    test "works as expected for creating the first round of a single_elimination tournament" do
      tournament = tournament_with_players_fixture(%{type: :single_elimination, length: 2})
      {:ok, rnd} = Tournaments.create_next_round(tournament, 0)

      assert rnd.number == 1

      rnd = Rounds.get_round_with_games(rnd.id)
      assert length(rnd.games) == 2
    end
  end
end
