defmodule Elswisser.Rounds.Game do
  use Ecto.Schema
  import Ecto.Changeset

  schema "games" do
    field :black, :integer
    field :game_link, :string
    field :result, :integer
    field :round, :integer
    field :white, :integer

    timestamps()
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:white, :black, :result, :round, :game_link])
    |> validate_required([:white, :black, :result, :round, :game_link])
  end
end
