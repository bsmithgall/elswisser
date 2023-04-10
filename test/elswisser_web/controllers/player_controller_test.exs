defmodule ElswisserWeb.PlayerControllerTest do
  use ElswisserWeb.ConnCase

  import Elswisser.PlayersFixtures

  @create_attrs %{name: "some name", rating: 42}
  @update_attrs %{name: "some updated name", rating: 43}
  @invalid_attrs %{name: nil, rating: nil}

  describe "index" do
    test "lists all players", %{conn: conn} do
      conn = get(conn, ~p"/players")
      assert html_response(conn, 200) =~ "Listing Players"
    end
  end

  describe "new player" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/players/new")
      assert html_response(conn, 200) =~ "New Player"
    end
  end

  describe "create player" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/players", player: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/players/#{id}"

      conn = get(conn, ~p"/players/#{id}")
      assert html_response(conn, 200) =~ "Player #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/players", player: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Player"
    end
  end

  describe "edit player" do
    setup [:create_player]

    test "renders form for editing chosen player", %{conn: conn, player: player} do
      conn = get(conn, ~p"/players/#{player}/edit")
      assert html_response(conn, 200) =~ "Edit Player"
    end
  end

  describe "update player" do
    setup [:create_player]

    test "redirects when data is valid", %{conn: conn, player: player} do
      conn = put(conn, ~p"/players/#{player}", player: @update_attrs)
      assert redirected_to(conn) == ~p"/players/#{player}"

      conn = get(conn, ~p"/players/#{player}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, player: player} do
      conn = put(conn, ~p"/players/#{player}", player: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Player"
    end
  end

  describe "delete player" do
    setup [:create_player]

    test "deletes chosen player", %{conn: conn, player: player} do
      conn = delete(conn, ~p"/players/#{player}")
      assert redirected_to(conn) == ~p"/players"

      assert_error_sent 404, fn ->
        get(conn, ~p"/players/#{player}")
      end
    end
  end

  defp create_player(_) do
    player = player_fixture()
    %{player: player}
  end
end
