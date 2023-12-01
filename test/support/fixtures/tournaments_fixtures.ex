defmodule Elswisser.TournamentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Elswisser.Tournaments` context.
  """

  @doc """
  Generate a tournament.
  """
  def tournament_fixture(attrs \\ %{}) do
    {:ok, tournament} =
      attrs
      |> Enum.into(%{
        name: "some name",
        type: :swiss
      })
      |> Elswisser.Tournaments.create_tournament()

    Elswisser.Tournaments.get_tournament!(tournament.id)
  end

  def tournament_with_players_fixture(attrs \\ %{}) do
    player1 = Elswisser.PlayersFixtures.player_fixture()
    player2 = Elswisser.PlayersFixtures.player_fixture()
    player3 = Elswisser.PlayersFixtures.player_fixture()
    player4 = Elswisser.PlayersFixtures.player_fixture()

    {:ok, tournament} =
      attrs
      |> Enum.into(%{
        name: "some name",
        type: :swiss,
        player_ids: [player1.id, player2.id, player3.id, player4.id]
      })
      |> Elswisser.Tournaments.create_tournament()

    Elswisser.Tournaments.get_tournament_with_players!(tournament.id)
  end
end
