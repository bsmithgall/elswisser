defmodule Elswisser.RoundsTest do
  use Elswisser.DataCase

  alias Elswisser.Rounds
  alias Elswisser.Tournaments

  describe "rounds" do
    alias Elswisser.Rounds.Round

    import Elswisser.RoundsFixtures

    @invalid_attrs %{number: nil, tournament_id: nil}

    test "get_round!/1 returns the round with given id" do
      round = round_fixture()
      assert Rounds.get_round!(round.id) == round
    end

    test "create_round/1 with valid data creates a round" do
      {:ok, tournament} = Tournaments.create_tournament(%{name: "test"})
      valid_attrs = %{number: 42, tournament_id: tournament.id}

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

  end
end
