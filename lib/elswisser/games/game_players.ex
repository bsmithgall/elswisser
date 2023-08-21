defmodule Elswisser.Games.GamePlayers do
  use Ecto.Schema
  import Ecto.Changeset

  schema "game_players" do
    field(:color, Ecto.Enum, values: [:white, :black])

    belongs_to(:player, Elswisser.Players.Player)
    belongs_to(:game, Elswisser.Games.Game)
  end

  @doc false
  def changeset(players, attrs) do
    players
    |> cast(attrs, [:color, :player_id, :game_id])
    |> validate_required([:color, :player_id, :game_id])
  end
end
