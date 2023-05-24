defmodule ElswisserWeb.TournamentControllerTest do
  use ElswisserWeb.ConnCase

  import Elswisser.TournamentsFixtures

  @create_attrs %{name: "some name", player_ids: [1, 2]}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  describe "index" do
    test "lists all tournaments", %{conn: conn} do
      conn = get(conn, ~p"/tournaments")
      assert html_response(conn, 200) =~ "Listing Tournaments"
    end
  end

  describe "new tournament" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/tournaments/new")
      assert html_response(conn, 200) =~ "New Tournament"
    end
  end

  describe "create tournament" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/tournaments", tournament: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/tournaments/#{id}"

      conn = get(conn, ~p"/tournaments/#{id}")
      assert html_response(conn, 200) =~ "Tournament #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/tournaments", tournament: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Tournament"
    end
  end

  describe "edit tournament" do
    setup [:create_tournament]

    test "renders form for editing chosen tournament", %{conn: conn, tournament: tournament} do
      conn = get(conn, ~p"/tournaments/#{tournament}/edit")
      assert html_response(conn, 200) =~ "Edit Tournament"
    end
  end

  describe "update tournament" do
    setup [:create_tournament]

    test "redirects when data is valid", %{conn: conn, tournament: tournament} do
      conn = put(conn, ~p"/tournaments/#{tournament}", tournament: @update_attrs)
      assert redirected_to(conn) == ~p"/tournaments/#{tournament}"

      conn = get(conn, ~p"/tournaments/#{tournament}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, tournament: tournament} do
      conn = put(conn, ~p"/tournaments/#{tournament}", tournament: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Tournament"
    end
  end

  describe "delete tournament" do
    setup [:create_tournament]

    test "deletes chosen tournament", %{conn: conn, tournament: tournament} do
      conn = delete(conn, ~p"/tournaments/#{tournament}")
      assert redirected_to(conn) == ~p"/tournaments"

      assert_error_sent 404, fn ->
        get(conn, ~p"/tournaments/#{tournament}")
      end
    end
  end

  defp create_tournament(_) do
    tournament = tournament_fixture()
    %{tournament: tournament}
  end
end
