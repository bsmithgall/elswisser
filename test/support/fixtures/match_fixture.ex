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
end
