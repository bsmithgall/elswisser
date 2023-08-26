defmodule Elswisser.Pairings.Bye do
  require Integer
  @bye_player_id -1

  def bye_player_id, do: @bye_player_id

  def bye_player,
    do: %Elswisser.Players.Player{
      id: @bye_player_id,
      name: "-- BYE --",
      rating: nil,
      white_games: [],
      black_games: []
    }
end
