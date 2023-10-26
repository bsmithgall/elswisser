defmodule Elswisser.Repo.Migrations.AddGameRatings do
  import Ecto.Query
  use Ecto.Migration

  alias Elswisser.Pairings.Bye
  alias Elswisser.Players.Player
  alias Elswisser.Games.Game
  alias Elswisser.Games
  alias Elswisser.Repo

  def up do
    alter table("games") do
      add :white_rating, :integer
      add :black_rating, :integer
    end

    flush()

    games =
      from(g in Game,
        order_by: [desc: g.finished_at, desc: g.inserted_at],
        select: %Game{
          id: g.id,
          white_id: g.white_id,
          black_id: g.black_id,
          white_rating_change: g.white_rating_change,
          black_rating_change: g.black_rating_change,
          round_id: g.round_id,
          tournament_id: g.tournament_id,
          result: g.result
        }
      )
      |> Repo.all()

    ratings =
      from(p in Player, where: p.id != -1, select: %{id: p.id, rating: p.rating})
      |> Repo.all()
      |> Enum.reduce(%{}, fn el, acc -> Map.put(acc, el.id, el.rating) end)

    unplayed_multi =
      Enum.filter(games, &is_nil(&1.result))
      |> Enum.reduce(Ecto.Multi.new(), fn g, multi ->
        Ecto.Multi.update(
          multi,
          g.id,
          Games.change_game(g, %{
            white_rating: Map.get(ratings, g.white_id),
            black_rating: Map.get(ratings, g.black_id)
          })
        )
      end)

    played_games = Enum.filter(games, &(!is_nil(&1.result)))

    played_multi =
      played_games
      |> Enum.reduce([], fn g, acc ->
        hd = if length(acc) == 0, do: ratings, else: hd(acc)

        [
          hd
          |> Map.replace(g.white_id, Map.get(hd, g.white_id) - g.white_rating_change)
          |> Map.replace(g.black_id, Map.get(hd, g.black_id) - g.black_rating_change)
          | acc
        ]
      end)
      |> Enum.reverse()
      |> Enum.zip(played_games)
      |> Enum.reduce(Ecto.Multi.new(), fn {ratings, g}, multi ->
        attrs = %{white_rating: Map.get(ratings, g.white_id)}

        attrs =
          if g.black_id != Bye.bye_player_id() do
            Map.put(attrs, :black_rating, Map.get(ratings, g.black_id))
          else
            attrs
          end

        Ecto.Multi.update(multi, g.id, Games.change_game(g, attrs))
      end)

    Ecto.Multi.append(unplayed_multi, played_multi) |> Repo.transaction()
  end

  def down do
    alter table("games") do
      remove :white_rating
      remove :black_rating
    end
  end
end
