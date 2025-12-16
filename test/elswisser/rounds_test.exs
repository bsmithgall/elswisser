defmodule Elswisser.RoundsTest do
  use Elswisser.DataCase

  alias Elswisser.Rounds
  alias Elswisser.Rounds.Round
  alias Elswisser.Tournaments
  alias Elswisser.Games
  alias Elswisser.Matches

  import Elswisser.RoundsFixtures
  import Elswisser.PlayersFixtures
  import Elswisser.MatchFixture
  import Elswisser.TournamentsFixtures

  describe "rounds" do
    @invalid_attrs %{number: nil, tournament_id: nil}

    test "get_round!/1 returns the round with given id" do
      round = round_fixture()
      assert Rounds.get_round!(round.id) == round
    end

    test "create_round/1 with valid data creates a round" do
      {:ok, tournament} = Tournaments.create_tournament(%{name: "test", type: :swiss})
      valid_attrs = %{number: 42, tournament_id: tournament.id, status: :playing}

      assert {:ok, %Round{} = round} = Rounds.create_round(valid_attrs)
      assert round.number == 42
      assert round.tournament_id == tournament.id
    end

    test "create_round/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Rounds.create_round(@invalid_attrs)
    end

    test "update_round/2 with valid data updates the round" do
      round = round_fixture()
      update_attrs = %{number: 43}

      assert {:ok, %Round{} = round} = Rounds.update_round(round, update_attrs)
      assert round.number == 43
    end

    test "update_round/2 with invalid data returns error changeset" do
      round = round_fixture()
      assert {:error, %Ecto.Changeset{}} = Rounds.update_round(round, @invalid_attrs)
      assert round == Rounds.get_round!(round.id)
    end

    test "set_playing/1 updates status properly" do
      round = round_fixture()

      assert {:ok, %Round{} = round} = Rounds.set_playing(round.id)
      assert Rounds.get_round!(round.id).status == :playing
    end

    test "set_complete/1 updates status properly" do
      round = round_fixture()

      assert {:ok, %Round{} = round} = Rounds.set_complete(round.id)
      assert Rounds.get_round!(round.id).status == :complete
    end
  end

  describe "ensure_matches_complete/2" do
    test "returns ok when all matches complete in single-game tournament" do
      {tournament, round} = tournament_and_round_fixture(:best_of, 1)
      match_with_games_fixture(round, tournament, [1])

      assert {:ok, 0} = Rounds.ensure_matches_complete(round.id, tournament)
    end

    test "returns error when match incomplete in single-game tournament" do
      {tournament, round} = tournament_and_round_fixture(:best_of, 1)
      match_with_games_fixture(round, tournament, [nil])

      assert {:error, "1 match(es) not complete yet!"} =
               Rounds.ensure_matches_complete(round.id, tournament)
    end

    test "returns ok when match complete in first_to tournament" do
      {tournament, round} = tournament_and_round_fixture(:first_to, 2)
      match_with_games_fixture(round, tournament, [1, -1])

      assert {:ok, 0} = Rounds.ensure_matches_complete(round.id, tournament)
    end

    test "returns error when match incomplete in first_to tournament" do
      {tournament, round} = tournament_and_round_fixture(:first_to, 2)
      match_with_games_fixture(round, tournament, [1])

      assert {:error, "1 match(es) not complete yet!"} =
               Rounds.ensure_matches_complete(round.id, tournament)
    end

    test "returns error with correct count for multiple incomplete matches" do
      {tournament, round} = tournament_and_round_fixture(:best_of, 3)

      for i <- 1..2 do
        p1 = player_fixture(%{name: "Player#{i}A"})
        p2 = player_fixture(%{name: "Player#{i}B"})

        {:ok, match} =
          Matches.create_match(%{
            board: i,
            display_order: i,
            round_id: round.id
          })

        {:ok, _} =
          Games.create_game(%{
            match_id: match.id,
            round_id: round.id,
            tournament_id: tournament.id,
            white_id: p1.id,
            black_id: p2.id,
            result: 1
          })
      end

      assert {:error, "2 match(es) not complete yet!"} =
               Rounds.ensure_matches_complete(round.id, tournament)
    end

    test "handles best_of format with early clinch correctly" do
      {tournament, round} = tournament_and_round_fixture(:best_of, 5)
      match_with_games_fixture(round, tournament, [1, -1, 1])

      assert {:ok, 0} = Rounds.ensure_matches_complete(round.id, tournament)
    end
  end
end
