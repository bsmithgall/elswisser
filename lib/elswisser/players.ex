defmodule Elswisser.Players do
  @moduledoc """
  The Players context.
  """

  import Ecto.Query, warn: false
  alias Elswisser.Pairings.Bye
  alias Ecto.Multi
  alias Elswisser.Players.ELO
  alias Elswisser.Repo

  alias Elswisser.Players.Player
  alias Elswisser.Games.Game
  alias Elswisser.Rounds

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

  def update_ratings_after_round(id) do
    rnd_with_games = Rounds.get_round_with_games(id)

    player_ids =
      Enum.reduce(rnd_with_games.games, MapSet.new(), fn g, acc ->
        put_id(acc, g.white_id) |> put_id(g.black_id)
      end)
      |> MapSet.to_list()

    with_k_factors = players_with_k_factor(player_ids)

    rnd_with_games.games
    |> Enum.filter(fn g ->
      g.white_id != Bye.bye_player_id() and g.black_id != Bye.bye_player_id()
    end)
    |> Enum.reduce(Multi.new(), fn g, multi ->
      {white, white_recalcs} = with_k_factors[g.white_id]
      {black, black_recalcs} = with_k_factors[g.black_id]

      {new_white, new_black} = ELO.recalculate(white_recalcs, black_recalcs, g.result)

      white_changeset = Player.changeset(white, %{rating: new_white})
      black_changeset = Player.changeset(black, %{rating: new_black})

      Multi.update(multi, {:rating, g.white_id}, white_changeset)
      |> Multi.update({:rating, g.black_id}, black_changeset)
    end)
    |> Repo.transaction()
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

  def players_with_k_factor(ids) when is_list(ids) do
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

  defp put_id(set, -1), do: set
  defp put_id(set, player_id), do: MapSet.put(set, player_id)
end
