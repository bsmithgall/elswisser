defmodule ElswisserWeb.RoundLive.PairingTest do
  use ElswisserWeb.ConnCase

  alias Elswisser.Rounds
  alias Elswisser.Tournaments

  import Phoenix.LiveViewTest
  import Elswisser.TournamentsFixtures

  setup :register_and_log_in_user

  # This is a massive integration test that steps through the first two
  # rounds of a swiss tournament to make sure everything is working correctly.
  test "pages through the tournament properly", %{conn: conn} do
    ### Create and start tournament
    tournament = tournament_with_n_players_fixture(8)
    {:ok, rnd} = Tournaments.create_next_round(tournament, 1)

    ### First round pairings

    {:ok, lv, html} =
      live_isolated(conn, ElswisserWeb.RoundLive.Pairing,
        session: %{
          "round_id" => rnd.id,
          "round_number" => rnd.number,
          "tournament_id" => tournament.id,
          "roster" => tournament.players
        }
      )

    assert html =~ "Auto-pair remaining players"

    lv |> element("button", "Auto-pair remaining players") |> render_click()

    {path, flash} = assert_redirect(lv)

    assert flash["info"] == "All pairings finished!"
    assert path == ~p"/tournaments/#{tournament}/rounds/#{rnd}"

    ### First round matchups

    {:ok, lv, _} =
      live_isolated(conn, ElswisserWeb.RoundLive.Round,
        session: %{
          "round_id" => rnd.id,
          "tournament_type" => tournament.type,
          "current_user" => "hi"
        }
      )

    rnd1 = Rounds.get_round_with_games(rnd.id)

    for game <- rnd1.games do
      lv
      |> element("#game-#{game.id}-result")
      |> render_change(%{"result" => "1", "_target" => ["result"]})
    end

    {:ok, rnd} = Rounds.finalize_round(rnd1, tournament)

    ### Second round pairings

    {:ok, lv, html} =
      live_isolated(conn, ElswisserWeb.RoundLive.Pairing,
        session: %{
          "round_id" => rnd.id,
          "round_number" => rnd.number,
          "tournament_id" => tournament.id,
          "roster" => tournament.players
        }
      )

    assert html =~ "Auto-pair remaining players"

    lv |> element("button", "Auto-pair remaining players") |> render_click()

    {path, flash} = assert_redirect(lv)

    assert flash["info"] == "All pairings finished!"
    assert path == ~p"/tournaments/#{tournament}/rounds/#{rnd}"

    ### Second round pairings are not the same as the first round

    rnd2 = Rounds.get_round_with_games(rnd.id)

    rnd1_pairings =
      rnd1.games
      |> Enum.map(&([&1.white_id, &1.black_id] |> Enum.sort()))
      |> Enum.into(MapSet.new())

    rnd2_pairings =
      rnd2.games
      |> Enum.map(&([&1.white_id, &1.black_id] |> Enum.sort()))
      |> Enum.into(MapSet.new())

    assert MapSet.difference(rnd1_pairings, rnd2_pairings) == rnd1_pairings
    assert MapSet.difference(rnd2_pairings, rnd1_pairings) == rnd2_pairings
  end
end
