defmodule Elswisser.Tournaments.TournamentPlayer do
  use Ecto.Schema

  @primary_key false
  schema "tournament_players" do
    belongs_to :player, Elswisser.Players.Player
    belongs_to :tournament, Elswisser.Tournaments.Tournament
  end
end
