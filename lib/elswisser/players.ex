defmodule Elswisser.Players do
  @moduledoc """
  The Players context.
  """

  import Ecto.Query, warn: false
  alias Elswisser.Repo

  alias Elswisser.Players.Player
  alias Elswisser.Games.Game

  @doc """
  Returns the list of players.

  ## Examples

      iex> list_players()
      [%Player{}, ...]

  """
  def list_players do
    Repo.all(Player)
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

  @doc """
  For a given tournament_id and round_id, find all players that have yet to be
  paired into a game together.
  """
  def get_unpaired_players(tournament_id, round_id) do
    white_games =
      Game.from()
      |> Game.where_tournament_id(tournament_id)
      |> Game.where_round_id(round_id)
      |> Game.select_white_id()

    black_games =
      Game.from()
      |> Game.where_tournament_id(tournament_id)
      |> Game.where_round_id(round_id)
      |> Game.select_black_id()

    all_games = white_games |> union(^black_games)

    Player.from()
    |> Player.where_tournament_id(tournament_id)
    |> Player.where_not_matching(all_games)
    |> Repo.all()
  end

  def get_player_with_k_factor(id) when is_integer(id) do
    {player, game_count} =
      from(
        p in Player,
        join:
          g in subquery(
            from(g in Game,
              where: g.white_id == ^id or g.black_id == ^id,
              select: %{id: ^id, ct: count(g.id)}
            )
          ),
        on: p.id == g.id,
        select: {p, g.ct}
      )
      |> Repo.one()

    cond do
      is_nil(player) -> {:error, "Player not found"}
      game_count < 30 -> {:ok, {player, 40}}
      player.rating > 2100 -> {:ok, {player, 10}}
      true -> {:ok, {player, 20}}
    end
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
end
