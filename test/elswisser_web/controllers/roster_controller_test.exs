defmodule ElswisserWeb.RosterControllerTest do
  use ElswisserWeb.ConnCase

  import Elswisser.TournamentsFixtures

  @update_attrs [1, 2, 3, 4]

  describe "index" do
    test "lists all rosters", %{conn: conn} do
      tournament = tournament_with_players_fixture()
      conn = get(conn, ~p"/tournaments/#{tournament}/roster")
      assert html_response(conn, 200) =~ "Roster for #{tournament.name}"
    end
  end

  describe "update roster" do
    setup [:create_roster]

    test "redirects when data is valid", %{conn: conn, tournament: tournament} do
      conn = put(conn, ~p"/tournaments/#{tournament}/roster", player_ids: @update_attrs)
      assert redirected_to(conn) == ~p"/tournaments/#{tournament}/roster"

      conn = get(conn, ~p"/tournaments/#{tournament}/roster")
      assert html_response(conn, 200)
    end
  end

  defp create_roster(_) do
    tournament = tournament_with_players_fixture()
    %{tournament: tournament}
  end
end
