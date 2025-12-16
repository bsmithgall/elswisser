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

  def tournament_with_n_players_fixture(n, attrs \\ %{}) do
    players = 0..n |> Enum.map(fn _ -> Elswisser.PlayersFixtures.player_fixture() end)

    {:ok, tournament} =
      attrs
      |> Enum.into(%{
        name: "some name",
        type: :swiss,
        player_ids: players |> Enum.map(& &1.id)
      })
      |> Elswisser.Tournaments.create_tournament()

    Elswisser.Tournaments.get_tournament_with_players!(tournament.id)
  end

  @doc """
  Create a tournament with specific match format configuration and a round.
  Returns {tournament, round} tuple.
  """
  def tournament_and_round_fixture(match_format, points_to_win, allow_draws \\ true) do
    {:ok, tournament} =
      Elswisser.Tournaments.create_tournament(%{
        name: "test",
        type: :swiss,
        match_format: match_format,
        points_to_win: points_to_win,
        allow_draws: allow_draws
      })

    {:ok, round} =
      Elswisser.Rounds.create_round(%{
        number: 1,
        tournament_id: tournament.id,
        status: :playing
      })

    {tournament, round}
  end
end
