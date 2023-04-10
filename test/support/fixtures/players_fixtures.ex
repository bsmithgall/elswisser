defmodule Elswisser.PlayersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Elswisser.Players` context.
  """

  @doc """
  Generate a player.
  """
  def player_fixture(attrs \\ %{}) do
    {:ok, player} =
      attrs
      |> Enum.into(%{
        name: "some name",
        rating: 42
      })
      |> Elswisser.Players.create_player()

    player
  end
end
