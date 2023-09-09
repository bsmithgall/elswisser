defmodule Elswisser.Games do
  import Ecto.Query, warn: false
  alias Elswisser.Repo

  alias Elswisser.Games.Game

  def get_game(id) do
    Game.from() |> Game.where_id(id) |> Repo.one()
  end

  def get_game!(id) do
    Game.from() |> Game.where_id(id) |> Repo.one!()
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

  def get_history_for_player(player_id) do
    Game.from()
    |> Game.where_player_id(player_id)
    |> Game.where_finished()
    |> Game.with_both_players()
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

  def update_game(%Game{} = game, attrs) do
    game |> Game.changeset(attrs) |> Repo.update()
  end

  def change_game(%Game{} = game, attrs \\ %{}) do
    Game.changeset(game, attrs)
  end

  def add_pgn(id, pgn, game_link) do
    case get_game(id) do
      nil -> {:error, "Could not find game!"}
      game -> update_game(game, %{pgn: pgn, game_link: game_link})
    end
  end

  def fetch_pgn(game_id, game_link) when is_nil(game_id) or is_nil(game_link) do
    {:error, "Cannot fetch PGN without valid game ID and game source."}
  end

  def fetch_pgn(game_id, game_link) do
    with {:ok, fetchfn} <- parse_game_source(game_link),
         {:ok, pgn} <- fetchfn.(game_link),
         {:ok, game} <- add_pgn(game_id, pgn, game_link) do
      {:ok, %{game_id: game.id, pgn: pgn}}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def delete_game(%Game{} = game) do
    Repo.delete(game)
  end

  defp parse_game_source(game_link) do
    cond do
      is_nil(game_link) -> {:error, "Missing game link"}
      String.contains?(game_link, "chess.com/") -> {:ok, &Elswisser.Games.Chesscom.fetch_pgn/1}
      String.contains?(game_link, "lichess.org/") -> {:ok, &Elswisser.Games.Lichess.fetch_pgn/1}
      true -> {:error, "Could not find valid game link"}
    end
  end
end
