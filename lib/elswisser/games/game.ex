defmodule Elswisser.Games.Game do
  use Ecto.Schema
  import Ecto.Changeset

  schema "games" do
    field(:game_link, :string)
    field(:result, :integer)

    belongs_to(:round, Elswisser.Rounds.Round)
    belongs_to(:tournament, Elswisser.Tournaments.Tournament)
    belongs_to(:white, Elswisser.Players.Player)
    belongs_to(:black, Elswisser.Players.Player)

    timestamps()
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:white_id, :black_id, :result, :round_id, :game_link, :tournament_id])
    |> validate_required([:white_id, :black_id, :result, :round_id, :tournament_id])
  end
end
