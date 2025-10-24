defmodule Elswisser.Pairings.DoubleElimination.CreateTest do
  alias Elswisser.Tournaments
  alias Elswisser.Pairings.DoubleElimination
  use Elswisser.DataCase

  import Elswisser.TournamentsFixtures

  test "create_all/1 works as expected" do
    tournament = tournament_with_players_fixture()

    {:ok, id} = DoubleElimination.create_all(tournament)

    tournament = Tournaments.get_tournament_with_all(id)

    assert length(tournament.rounds) == 6

    assert tournament.rounds |> Enum.frequencies_by(& &1.type) == %{
             championship: 2,
             loser: 2,
             winner: 2
           }

    assert Enum.flat_map(tournament.rounds, fn r -> r.matches end) |> length() == 7
  end
end
