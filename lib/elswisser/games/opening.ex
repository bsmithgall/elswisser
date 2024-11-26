defmodule Elswisser.Games.Opening do
  use Ecto.Schema
  import Ecto.Changeset

  schema "openings" do
    field :name, :string
    field :eco, :string
    field :pgn, :string
  end

  @doc false
  def changeset(opening, attrs) do
    opening
    |> cast(attrs, [:eco, :name, :pgn])
    |> validate_required([:eco, :name, :pgn])
  end
end
