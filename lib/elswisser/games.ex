defmodule Elswisser.Games do
  import Ecto.Query, warn: false
  alias Elswisser.Repo

  alias Elswisser.Games.Game

  def get_game!(id) do
    Repo.get!(Game, id)
  end

  def get_game_with_players!(id) do
    from(g in Game)
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
