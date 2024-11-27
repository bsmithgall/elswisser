defmodule Elswisser.Openings.Opening do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  schema "openings" do
    field :name, :string
    field :eco, :string
    field :pgn, :string

    has_many(:games, Elswisser.Games.Game)
  end

  @doc false
  def changeset(opening, attrs) do
    opening
    |> cast(attrs, [:eco, :name, :pgn])
    |> validate_required([:eco, :name, :pgn])
  end

  def from do
    from(o in __MODULE__, as: :opening)
  end

  def where_pgn(query, pgn) do
    from([opening: o] in query, where: o.pgn == ^pgn)
  end
end
