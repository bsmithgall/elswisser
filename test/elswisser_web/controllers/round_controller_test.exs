defmodule ElswisserWeb.RoundControllerTest do
  use ElswisserWeb.ConnCase

  import Elswisser.RoundsFixtures

  describe "index" do
    setup [:create_round]

    test "lists all rounds", %{conn: conn, round: round} do
      conn = get(conn, ~p"/tournaments/#{round.tournament_id}/rounds/#{round}")
      assert html_response(conn, 200) =~ "Roster"
    end
  end

  defp create_round(_) do
    round = round_fixture()
    %{round: round}
  end
end
