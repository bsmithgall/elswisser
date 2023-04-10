defmodule Elswisser.RoundsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Elswisser.Rounds` context.
  """

  @doc """
  Generate a round.
  """
  def round_fixture(attrs \\ %{}) do
    {:ok, round} =
      attrs
      |> Enum.into(%{
        number: 42,
        tournament_id: 42
      })
      |> Elswisser.Rounds.create_round()

    round
  end
end
