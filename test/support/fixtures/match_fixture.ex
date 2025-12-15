defmodule Elswisser.MatchFixture do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Elswisser.Matches` context.
  """

  @doc """
  Generate a match.
  """
  def match_fixture() do
    rnd = Elswisser.RoundsFixtures.round_fixture()

    {:ok, game} =
      Elswisser.Matches.create_match(%{
        board: 1,
        display_order: 1,
        round_id: rnd.id
      })

    game
  end

  def match_fixture(%Elswisser.Rounds.Round{} = rnd, attrs \\ %{}) do
    {:ok, match} =
      attrs
      |> Enum.into(%{
        board: 1,
        display_order: 1,
        round_id: rnd.id
      })
      |> Elswisser.Matches.create_match()

    match
  end

  @doc """
  Create a match with specific game results.
  game_results is a list of results (1, 0, -1, or nil) where players alternate colors.
  """
  def match_with_games_fixture(round, tournament, game_results) do
    player1 = Elswisser.PlayersFixtures.player_fixture(%{name: "Alice"})
    player2 = Elswisser.PlayersFixtures.player_fixture(%{name: "Bob"})

    {:ok, match} =
      Elswisser.Matches.create_match(%{
        board: 1,
        display_order: 1,
        round_id: round.id,
        player_one_id: player1.id,
        player_two_id: player2.id,
        player_one_seed: 1,
        player_two_seed: 2
      })

    Enum.with_index(game_results)
    |> Enum.each(fn {result, idx} ->
      {:ok, _} =
        Elswisser.Games.create_game(%{
          match_id: match.id,
          round_id: round.id,
          tournament_id: tournament.id,
          white_id: if(rem(idx, 2) == 0, do: player1.id, else: player2.id),
          black_id: if(rem(idx, 2) == 0, do: player2.id, else: player1.id),
          result: result
        })
    end)

    match
  end
end
