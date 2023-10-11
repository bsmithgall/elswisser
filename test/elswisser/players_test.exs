defmodule Elswisser.PlayersTest do
  use Elswisser.DataCase

  alias Elswisser.Players
  alias Elswisser.Players.ELO

  describe "players" do
    alias Elswisser.Players.Player

    import Elswisser.PlayersFixtures

    @invalid_attrs %{name: nil, rating: nil}

    test "list_players/0 returns all players" do
      player = player_fixture()
      assert Players.list_players() == [player]
    end

    test "get_player!/1 returns the player with given id" do
      player = player_fixture()
      assert Players.get_player!(player.id) == player
    end

    test "create_player/1 with valid data creates a player" do
      valid_attrs = %{name: "some name", rating: 42}

      assert {:ok, %Player{} = player} = Players.create_player(valid_attrs)
      assert player.name == "some name"
      assert player.rating == 42
    end

    test "create_player/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Players.create_player(@invalid_attrs)
    end

    test "update_player/2 with valid data updates the player" do
      player = player_fixture()
      update_attrs = %{name: "some updated name", rating: 43}

      assert {:ok, %Player{} = player} = Players.update_player(player, update_attrs)
      assert player.name == "some updated name"
      assert player.rating == 43
    end

    test "update_player/2 with invalid data returns error changeset" do
      player = player_fixture()
      assert {:error, %Ecto.Changeset{}} = Players.update_player(player, @invalid_attrs)
      assert player == Players.get_player!(player.id)
    end

    test "delete_player/1 deletes the player" do
      player = player_fixture()
      assert {:ok, %Player{}} = Players.delete_player(player)
      assert_raise Ecto.NoResultsError, fn -> Players.get_player!(player.id) end
    end

    test "change_player/1 returns a player changeset" do
      player = player_fixture()
      assert %Ecto.Changeset{} = Players.change_player(player)
    end
  end

  describe "ELO" do
    test "1500 beats 1200 with K-factor of 40 yields +6" do
      assert ELO.recalculate(1500, 1200, 40, 1) == {1500 + 6, 6}
      assert ELO.recalculate(1200, 1500, 40, -1) == {1200 - 6, -6}
    end

    test "1400 draw with any K-factor yields no change" do
      assert ELO.recalculate(1400, 1400, 40, 0) == {1400, 0}
      assert ELO.recalculate(1400, 1400, 40, 0) == {1400, 0}
    end

    test "800 beats 1600 with K-factor of 40 yields +40" do
      assert ELO.recalculate(800, 1600, 40, 1) == {800 + 40, 40}
      assert ELO.recalculate(1600, 800, 40, -1) == {1600 - 40, -40}
    end

    test "800 (with black) beats 1600 with K-factor of 40 yields +40" do
      assert ELO.recalculate(1600, 800, 40, -1) == {1600 - 40, -40}
      assert ELO.recalculate(800, 1600, 40, 1) == {800 + 40, 40}
    end

    test "rating cannot fall below 100" do
      assert ELO.recalculate(100, 110, 40, -1) == {100, 0}
      assert ELO.recalculate(110, 100, 40, 1) == {100 + 29, 19}
    end
  end
end
