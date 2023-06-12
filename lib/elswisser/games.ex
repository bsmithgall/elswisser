defmodule Elswisser.Games do
  import Ecto.Query, warn: false
  alias Elswisser.Repo

  alias Elswisser.Games.Game

  def get_game!(id) do
    Game.from() |> Game.where_id(id) |> Repo.one!()
  end

  def create_game(attrs \\ %{}) do
    %Game{}
    |> Game.changeset(attrs)
    |> Repo.insert()
  end

  def get_games_from_tournament_for_player(tournament_id, player_id) do
    Game.from()
    |> Game.where_tournament_id(tournament_id)
    |> Game.where_player_id(player_id)
    |> Repo.all()
  end

  def get_games_from_tournament_for_player(tournament_id, player_id, roster) do
    Enum.map(get_games_from_tournament_for_player(tournament_id, player_id), fn game ->
      Game.load_players_from_roster(game, roster)
    end)
  end

  def get_game_with_players!(id) do
    Game.from()
    |> Game.where_id(id)
    |> Game.with_black_player()
    |> Game.with_white_player()
    |> Game.preload_players()
    |> Repo.one!()
  end

  def update_game(%Game{} = game, attrs) do
    game |> Game.changeset(attrs) |> Repo.update()
  end

  def change_game(%Game{} = game, attrs \\ %{}) do
    Game.changeset(game, attrs)
  end
end
