defmodule Elswisser.Rounds.Game do
  use Ecto.Schema
  import Ecto.Changeset

  alias Elswisser.Rounds.Round

  schema "games" do
    field :black, :integer
    field :game_link, :string
    field :result, :integer
    field :white, :integer

    belongs_to :round, Round

    timestamps()
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:white, :black, :result, :round_id, :game_link])
    |> validate_required([:white, :black, :result, :round_id])
  end
end
