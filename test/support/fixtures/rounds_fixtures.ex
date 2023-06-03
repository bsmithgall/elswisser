defmodule Elswisser.RoundsFixtures do
  alias Elswisser.Tournaments

  @moduledoc """
  This module defines test helpers for creating
  entities via the `Elswisser.Rounds` context.
  """

  @doc """
  Generate a round.
  """
  def round_fixture(attrs \\ %{}) do
    {:ok, tournament} = Tournaments.create_tournament(%{name: "test"})

    {:ok, round} =
      attrs
      |> Enum.into(%{
        number: 42,
        status: :playing,
        tournament_id: tournament.id
      })
      |> Elswisser.Rounds.create_round()

    round
  end
end
