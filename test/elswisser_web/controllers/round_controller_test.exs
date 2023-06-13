defmodule ElswisserWeb.RoundControllerTest do
  use ElswisserWeb.ConnCase

  import Elswisser.RoundsFixtures
  import Elswisser.TournamentsFixtures

  describe "show" do
    setup [:create_round]

    test "Shows correct round page", %{conn: conn, round: round} do
      conn = get(conn, ~p"/tournaments/#{round.tournament_id}/rounds/#{round}")
      assert html_response(conn, 200) =~ "Round"
    end

    test "404 when round not in tournament", %{conn: conn, round: round} do
      conn = get(conn, ~p"/tournaments/#{round.tournament_id}/rounds/1000000")
      assert html_response(conn, 404)
    end
  end

  describe "new" do
    test "create new round successfully", %{conn: conn} do
      tournament = tournament_fixture()
      conn = post(conn, ~p"/tournaments/#{tournament}/rounds", %{number: "1"})

      assert %{tournament_id: tournament_id, id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/tournaments/#{tournament_id}/rounds/#{id}"

      conn = get(conn, ~p"/tournaments/#{tournament_id}/rounds/#{id}")
      assert html_response(conn, 200) =~ "Round 1"
    end
  end

  defp create_round(_) do
    round = round_fixture()
    %{round: round}
  end
end
