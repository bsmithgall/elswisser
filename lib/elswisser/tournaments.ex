defmodule Elswisser.Tournaments do
  @moduledoc """
  The Tournaments context.
  """

  import Ecto.Query, warn: false
  alias Elswisser.Repo

  alias Elswisser.Tournaments.Tournament
  alias Elswisser.Players.Player
  alias Elswisser.Rounds.Round
  alias Elswisser.Rounds.Game

  @doc """
  Returns the list of tournaments.

  ## Examples

      iex> list_tournaments()
      [%Tournament{}, ...]

  """
  def list_tournaments do
    Repo.all(Tournament)
  end

  @doc """
  Gets a single tournament, with associated players.

  Raises `Ecto.NoResultsError` if the Tournament does not exist.

  ## Examples

      iex> get_tournament!(123)
      %Tournament{}

      iex> get_tournament!(456)
      ** (Ecto.NoResultsError)

  """
  def get_tournament!(id) do
    Tournament
    |> Repo.get!(id)
  end

  def get_tournament_with_players!(id) do
    Tournament
    |> Repo.get!(id)
    |> Repo.preload(:players)
  end

  def get_tournament_with_all!(id) do
    Tournament
    |> Repo.get!(id)
    |> Repo.preload(:players)
    |> Repo.preload(:rounds)
  end

  def get_all_games_in_tournament!(id) do
    Repo.all(
      from g in Game,
        join: r in Round,
        on: g.round_id == r.id,
        join: t in Tournament,
        on: r.tournament_id == t.id,
        where: t.id == ^id,
        select: {g, r.number}
    )
    |> Enum.map(fn x -> %{game: elem(x, 0), rnd: elem(x, 1)} end)
  end

  @doc """
  Creates a tournament.

  ## Examples

      iex> create_tournament(%{field: value})
      {:ok, %Tournament{}}

      iex> create_tournament(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_tournament(attrs \\ %{}) do
    %Tournament{}
    |> change_tournament(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a tournament.

  ## Examples

      iex> update_tournament(tournament, %{field: new_value})
      {:ok, %Tournament{}}

      iex> update_tournament(tournament, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_tournament(%Tournament{} = tournament, attrs) do
    tournament
    |> change_tournament(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a tournament.

  ## Examples

      iex> delete_tournament(tournament)
      {:ok, %Tournament{}}

      iex> delete_tournament(tournament)
      {:error, %Ecto.Changeset{}}

  """
  def delete_tournament(%Tournament{} = tournament) do
    Repo.delete(tournament)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tournament changes.

  ## Examples

      iex> change_tournament(tournament)
      %Ecto.Changeset{data: %Tournament{}}

  """
  def change_tournament(%Tournament{} = tournament, attrs \\ %{}) do
    players = list_players_by_id(attrs[:player_ids])
    len = calculate_length(players)

    rounds =
      if is_nil(tournament.id) do
        ensure_rounds(len)
      else
        ensure_rounds(len, tournament.id)
      end

    tournament
    |> Repo.preload(:players)
    |> Repo.preload(:rounds)
    |> Tournament.changeset(attrs |> ensure_atom |> Map.merge(%{length: len}))
    |> Ecto.Changeset.put_assoc(:players, players)
    |> Ecto.Changeset.put_assoc(:rounds, rounds)
  end

  def empty_changeset(%Tournament{} = tournament, attrs \\ %{}) do
    tournament
    |> Tournament.changeset(attrs)
  end

  def list_players_by_id(nil), do: list_players_by_id([])

  def list_players_by_id(player_ids) when is_list(player_ids) do
    Repo.all(from p in Player, where: p.id in ^player_ids)
  end

  def calculate_length(players) when is_list(players) do
    if Enum.empty?(players) do
      0
    else
      length(players) |> Math.log2() |> ceil()
    end
  end

  def calculate_length(_), do: 0

  def ensure_rounds(len) do
    Enum.map(1..len, fn n -> %{number: n} end)
  end

  @doc """
  Ensures that there are sufficient rounds if we add a new player and it gets
  pushed over the previous threshold for number of swiss games.
  """
  def ensure_rounds(len, id) do
    rounds = Repo.all(from(r in Round, where: r.tournament_id == ^id))

    cond do
      length(rounds) < len ->
        rounds ++ Enum.map((length(rounds) + 1)..len, fn n ->
          %{tournament_id: id, number: n}
        end)

      true ->
        rounds
    end
  end

  defp ensure_atom(attrs) when is_map(attrs) do
    Enum.reduce(attrs, %{}, fn
      {key, value}, acc when is_atom(key) -> Map.put(acc, key, value)
      {key, value}, acc when is_binary(key) -> Map.put(acc, String.to_existing_atom(key), value)
    end)
  end
end
