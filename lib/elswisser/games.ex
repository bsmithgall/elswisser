defmodule Elswisser.Games do
  import Ecto.Query, warn: false
  alias Elswisser.Repo

  alias Elswisser.Games.Game

  def get_game!(id) do
    Repo.get!(Game, id)
  end

  def get_game_with_players!(id) do
    Repo.one!(
      from g in Game,
        join: w in assoc(g, :white),
        join: b in assoc(g, :black),
        where: g.id == ^id,
        preload: [white: w, black: b]
    )
  end

  def get_games_for_round!(round_id) do
    Repo.all(
      from g in Game,
        left_join: w in Elswisser.Players.Player,
        on: g.white_id == w.id,
        left_join: b in Elswisser.Players.Player,
        on: g.black_id == b.id,
        where: g.round_id == ^round_id,
        select: {g, w, b}
    )
    |> Enum.map(fn {g, w, b} -> %{id: g.id, game: g, white: w, black: b} end)
  end

  def update_game(%Game{} = game, attrs) do
    game |> Game.changeset(attrs) |> Repo.update()
  end
end
