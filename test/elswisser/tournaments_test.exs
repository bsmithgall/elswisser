defmodule Elswisser.TournamentsTest do
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
      valid_attrs = %{name: "some name"}

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
end
