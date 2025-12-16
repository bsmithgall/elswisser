defmodule Elswisser.GamesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Elswisser.Games` context.
  """

  @doc """
  Generate a game.
  """
  def game_fixture(attrs \\ %{}) do
    rnd = Elswisser.RoundsFixtures.round_fixture()
    match = Elswisser.MatchFixture.match_fixture(rnd)
    white = Elswisser.PlayersFixtures.player_fixture()
    black = Elswisser.PlayersFixtures.player_fixture()

    {:ok, game} =
      attrs
      |> Enum.into(%{
        white_id: white.id,
        black_id: black.id,
        round_id: rnd.id,
        match_id: match.id,
        tournament_id: rnd.tournament_id
      })
      |> Elswisser.Games.create_game()

    game
  end

  def game_for_players_fixture(
        %Elswisser.Players.Player{} = white,
        %Elswisser.Players.Player{} = black,
        attrs \\ %{}
      ) do
    rnd = Elswisser.RoundsFixtures.round_fixture()
    match = Elswisser.MatchFixture.match_fixture(rnd)

    {:ok, game} =
      attrs
      |> Enum.into(%{
        white_id: white.id,
        black_id: black.id,
        round_id: rnd.id,
        match_id: match.id,
        tournament_id: rnd.tournament_id
      })
      |> Elswisser.Games.create_game()

    game
  end

  def game_fixture(
        %Elswisser.Rounds.Round{} = rnd,
        %Elswisser.Players.Player{} = white,
        %Elswisser.Players.Player{} = black,
        attrs \\ %{}
      ) do
    match = Elswisser.MatchFixture.match_fixture(rnd)

    {:ok, game} =
      attrs
      |> Enum.into(%{
        white_id: white.id,
        black_id: black.id,
        round_id: rnd.id,
        match_id: match.id,
        tournament_id: rnd.tournament_id
      })
      |> Elswisser.Games.create_game()

    game
  end
end
