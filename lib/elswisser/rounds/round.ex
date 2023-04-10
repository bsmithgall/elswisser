defmodule Elswisser.Rounds.Round do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rounds" do
    field :number, :integer

    belongs_to :tournament, Elswisser.Tournaments.Tournament

    timestamps()
  end

  @doc false
  def changeset(round, attrs) do
    round
    |> cast(attrs, [:number, :tournament_id])
    |> validate_required([:number, :tournament_id])
  end
end
