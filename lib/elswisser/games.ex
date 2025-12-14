defmodule Elswisser.Games do
  import Ecto.Query, warn: false
  alias Elswisser.Repo

  alias Elswisser.Games.Game
  alias Elswisser.Games.PgnProvider
  alias Elswisser.Rounds.Round
  alias Elswisser.Tournaments.Tournament

  def get_game(id) do
    Game.from() |> Game.where_id(id) |> Repo.one()
  end

  def get_game!(id) do
    Game.from() |> Game.where_id(id) |> Repo.one!()
  end

  def get_games_with_round_number_for_tournament(tournament_id) do
    Repo.all(
      from(g in Game,
        join: r in Round,
        on: g.round_id == r.id,
        join: t in Tournament,
        on: r.tournament_id == t.id,
        where: t.id == ^tournament_id,
        select: {g, r.number}
      )
    )
    |> Enum.map(fn x -> %{game: elem(x, 0), rnd: %Round{number: elem(x, 1)}} end)
  end

  def get_games_from_tournament_for_player(tournament_id, player_id) do
    Game.from()
    |> Game.where_tournament_id(tournament_id)
    |> Game.where_player_id(player_id)
    |> Repo.all()
  end

  def get_games_from_tournament_for_player(tournament_id, player_id, roster) do
    get_games_from_tournament_for_player(tournament_id, player_id)
    |> Enum.map(&Game.load_players_from_roster(&1, roster))
  end

  def get_game_with_players!(id) do
    Game.from()
    |> Game.where_id(id)
    |> Game.with_both_players()
    |> Game.preload_players()
    |> Repo.one!()
  end

  def get_game_with_players_and_opening!(id) do
    Game.from()
    |> Game.where_id(id)
    |> Game.with_both_players()
    |> Game.with_opening()
    |> Game.preload_players()
    |> Game.preload_opening()
    |> Repo.one!()
  end

  def get_history_for_player(player_id) do
    Game.from()
    |> Game.where_player_id(player_id)
    |> Game.where_finished()
    |> Game.with_both_players()
    |> Game.where_not_bye()
    |> Game.preload_players()
    |> Game.most_recent_first()
    |> Repo.all()
  end

  def create_game(attrs \\ %{}) do
    %Game{}
    |> Game.changeset(attrs)
    |> Repo.insert()
  end

  def create_games(games \\ []) do
    games
    |> Enum.with_index()
    |> Enum.reduce(Ecto.Multi.new(), fn {game, idx}, acc ->
      changeset = %Game{} |> Game.changeset(game)
      Ecto.Multi.insert(acc, {:game, idx}, changeset)
    end)
    |> Repo.transaction()
  end

  def update_game(%Game{opening_id: nil} = game, %{"pgn" => pgn} = attrs) do
    case Game.opening_from_pgn(pgn) do
      {:ok, {eco, opening_name, opening}} ->
        with_opening_details =
          attrs
          |> Enum.into(%{
            "eco" => eco,
            "opening_name" => opening_name,
            "opening_id" => opening.id
          })

        game |> Game.changeset(with_opening_details) |> Repo.update()

      _ ->
        game |> Game.changeset(attrs) |> Repo.update()
    end
  end

  def update_game(%Game{} = game, attrs) do
    game |> Game.changeset(attrs) |> Repo.update()
  end

  def change_game(%Game{} = game, attrs \\ %{}) do
    Game.changeset(game, attrs)
  end

  def delete_game(%Game{} = game) do
    Repo.delete(game)
  end

  def add_pgn(id, pgn, game_link) do
    with game when not is_nil(game) <- get_game(id),
         {:ok, {eco, opening_name, opening}} <- Game.opening_from_pgn(pgn) do
      opening_id = if is_nil(opening), do: nil, else: opening.id

      update_game(game, %{
        pgn: pgn,
        eco: eco,
        opening_name: opening_name,
        game_link: game_link,
        opening_id: opening_id
      })
    else
      nil -> {:error, "Could not find game!"}
      {:error, reason} -> {:error, reason}
    end
  end

  def fetch_pgn(game_id, game_link) when is_nil(game_id) or is_nil(game_link) do
    {:error, "Cannot fetch PGN without valid game ID and game source."}
  end

  def fetch_pgn(game_id, game_link) do
    with {:ok, provider} <- PgnProvider.find_provider(game_link),
         {:ok, pgn} <- provider.fetch_pgn(game_link),
         {:ok, game} <- add_pgn(game_id, pgn, game_link) do
      {:ok, %{game_id: game.id, pgn: pgn}}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def flip_players(%Game{} = game) do
    # Swap player colors within the game. Note: seeds are NOT swapped here
    # because seeds are match-level attributes (tournament seeding) and don't
    # change when colors are swapped within a game.
    case update_game(game, %{
           white_id: game.black.id,
           white_rating: game.black_rating,
           white_rating_change: game.black_rating_change,
           black_id: game.white.id,
           black_rating: game.white_rating,
           black_rating_change: game.white_rating_change
         }) do
      {:ok, game} ->
        {:ok, Repo.preload(game, [:white, :black])}

      {:error, changeset} ->
        {:error, changeset}
    end
  end
end
