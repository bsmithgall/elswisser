defmodule Elswisser.OpeningsFixture do
  alias Elswisser.Openings.Opening

  def opening_fixture(attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(%{
        name: "Barnes Opening",
        eco: "B00",
        pgn: "1. e4 f6"
      })

    {:ok, opening} = %Opening{} |> Opening.changeset(attrs) |> Elswisser.Repo.insert()

    opening
  end
end
