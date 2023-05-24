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
        name: "some name"
      })
      |> Elswisser.Tournaments.create_tournament()

    Elswisser.Tournaments.get_tournament!(tournament.id)
  end
end
