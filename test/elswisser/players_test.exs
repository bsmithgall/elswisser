defmodule Elswisser.PlayersTest do
  use Elswisser.DataCase

  alias Elswisser.Players

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
end
