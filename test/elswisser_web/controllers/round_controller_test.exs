defmodule ElswisserWeb.RoundControllerTest do
  use ElswisserWeb.ConnCase

  import Elswisser.RoundsFixtures

  @create_attrs %{number: 42, tournament_id: 42}
  @update_attrs %{number: 43, tournament_id: 43}
  @invalid_attrs %{number: nil, tournament_id: nil}

  describe "index" do
    test "lists all rounds", %{conn: conn} do
      conn = get(conn, ~p"/rounds")
      assert html_response(conn, 200) =~ "Listing Rounds"
    end
  end

  describe "new round" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/rounds/new")
      assert html_response(conn, 200) =~ "New Round"
    end
  end

  describe "create round" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/rounds", round: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/rounds/#{id}"

      conn = get(conn, ~p"/rounds/#{id}")
      assert html_response(conn, 200) =~ "Round #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/rounds", round: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Round"
    end
  end

  describe "edit round" do
    setup [:create_round]

    test "renders form for editing chosen round", %{conn: conn, round: round} do
      conn = get(conn, ~p"/rounds/#{round}/edit")
      assert html_response(conn, 200) =~ "Edit Round"
    end
  end

  describe "update round" do
    setup [:create_round]

    test "redirects when data is valid", %{conn: conn, round: round} do
      conn = put(conn, ~p"/rounds/#{round}", round: @update_attrs)
      assert redirected_to(conn) == ~p"/rounds/#{round}"

      conn = get(conn, ~p"/rounds/#{round}")
      assert html_response(conn, 200)
    end

    test "renders errors when data is invalid", %{conn: conn, round: round} do
      conn = put(conn, ~p"/rounds/#{round}", round: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Round"
    end
  end

  describe "delete round" do
    setup [:create_round]

    test "deletes chosen round", %{conn: conn, round: round} do
      conn = delete(conn, ~p"/rounds/#{round}")
      assert redirected_to(conn) == ~p"/rounds"

      assert_error_sent 404, fn ->
        get(conn, ~p"/rounds/#{round}")
      end
    end
  end

  defp create_round(_) do
    round = round_fixture()
    %{round: round}
  end
end
