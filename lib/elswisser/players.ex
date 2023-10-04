defmodule Elswisser.Players do
  @moduledoc """
  The Players context.
  """

  import Ecto.Query, warn: false
  require Elswisser.Players.Record
  alias Elswisser.Repo

  alias Elswisser.Players.Player
  alias Elswisser.Players.Record
  alias Elswisser.Games.Game

  @doc """
  Returns the list of players.

  ## Examples

      iex> list_players()
      [%Player{}, ...]

  """
  def list_players do
    Player.from() |> Player.excluding_bye_player() |> Repo.all()
  end

  def list_by_id(nil), do: list_by_id([])

  def list_by_id(ids) when is_list(ids) do
    Player.from() |> Player.where_id(ids) |> Repo.all()
  end

  @doc """
  Gets a single player.

  Raises `Ecto.NoResultsError` if the Player does not exist.

  ## Examples

      iex> get_player!(123)
      %Player{}

      iex> get_player!(456)
      ** (Ecto.NoResultsError)

  """
  def get_player!(id), do: Repo.get!(Player, id)

  def get_player_with_tournament_history(id, games) do
    Player.from()
    |> Player.where_id(id)
    |> preload(
      white_games:
        ^fn player_id -> Enum.filter(games, fn g -> Enum.member?(player_id, g.white_id) end) end,
      black_games:
        ^fn player_id -> Enum.filter(games, fn g -> Enum.member?(player_id, g.black_id) end) end
    )
    |> Repo.one()
  end

  def get_player_record(id) do
    Game.from()
    |> Game.where_player_id(id)
    |> Game.where_finished()
    |> Record.calculate_record(id)
    |> Repo.one()
  end

  def get_tournament_partipants(tournament_id) do
    Player.from()
    |> Player.where_tournament_id(tournament_id)
    |> Repo.all()
  end

  @doc """
  Creates a player.

  ## Examples

      iex> create_player(%{field: value})
      {:ok, %Player{}}

      iex> create_player(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_player(attrs \\ %{}) do
    %Player{}
    |> Player.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a player.

  ## Examples

      iex> update_player(player, %{field: new_value})
      {:ok, %Player{}}

      iex> update_player(player, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_player(%Player{} = player, attrs) do
    player
    |> Player.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a player.

  ## Examples

      iex> delete_player(player)
      {:ok, %Player{}}

      iex> delete_player(player)
      {:error, %Ecto.Changeset{}}

  """
  def delete_player(%Player{} = player) do
    Repo.delete(player)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking player changes.

  ## Examples

      iex> change_player(player)
      %Ecto.Changeset{data: %Player{}}

  """
  def change_player(%Player{} = player, attrs \\ %{}) do
    Player.changeset(player, attrs)
  end

  def with_k_factor(ids) when is_list(ids) do
    from(
      p in Player,
      join: w in subquery(Game.from() |> Game.count_white_games(ids)),
      on: p.id == w.id,
      join: b in subquery(Game.from() |> Game.count_black_games(ids)),
      on: p.id == b.id,
      where: p.id != -1,
      select: {p, w.ct + b.ct}
    )
    |> Repo.all()
    |> Enum.reduce(%{}, fn {player, games_played}, acc ->
      {player, k} = Player.with_k_factor(player, games_played)
      Map.put(acc, player.id, {player, {player.rating, k}})
    end)
  end
end
