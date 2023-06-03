defmodule Elswisser.Tournaments do
  @moduledoc """
  The Tournaments context.
  """

  import Ecto.Query, warn: false
  alias Elswisser.Repo

  alias Elswisser.Tournaments.Tournament
  alias Elswisser.Rounds.Round
  alias Elswisser.Games.Game

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

  def get_tournament_with_rounds!(id) do
    Tournament
    |> Repo.get!(id)
    |> Repo.preload(:rounds)
  end

  def current_round(%Tournament{} = tournament) do
    Enum.max_by(tournament.rounds, fn r -> r.number end)
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
    players = Elswisser.Players.list_by_id(attrs[:player_ids])
    len = calculate_length(players)

    tournament
    |> Repo.preload(:players)
    |> Repo.preload(:rounds)
    |> Tournament.changeset(attrs |> ensure_atom |> Map.merge(%{length: len}))
    |> maybe_put_players(players)
  end

  def empty_changeset(%Tournament{} = tournament, attrs \\ %{}) do
    tournament
    |> Tournament.changeset(attrs)
  end

  def get_roster(tournament_id) when is_nil(tournament_id) do
    Elswisser.Players.list_players()
    |> Enum.map(fn p -> Map.merge(p, %{in_tournament: false}) end)
    |> Enum.split(0)
  end

  def get_roster(tournament_id) do
    from(
      p in Elswisser.Players.Player,
      left_join:
        t in subquery(
          from(
            t in Elswisser.Tournaments.TournamentPlayer,
            where: t.tournament_id == ^tournament_id
          )
        ),
      on: p.id == t.player_id,
      select: {p, t.tournament_id}
    )
    |> Repo.all()
    |> Enum.map(fn {p, tid} -> Map.merge(p, %{in_tournament: !is_nil(tid)}) end)
    |> Enum.split_with(fn p -> p.in_tournament end)
  end

  def calculate_length(players) when is_list(players) do
    if Enum.empty?(players) do
      0
    else
      length(players) |> Math.log2() |> ceil()
    end
  end

  def calculate_length(_), do: 0

  defp ensure_atom(attrs) when is_map(attrs) do
    Enum.reduce(attrs, %{}, fn
      {key, value}, acc when is_atom(key) -> Map.put(acc, key, value)
      {key, value}, acc when is_binary(key) -> Map.put(acc, String.to_existing_atom(key), value)
    end)
  end

  defp maybe_put_players(changeset, players) do
    if Enum.empty?(players) do
      changeset
    else
      changeset |> Ecto.Changeset.put_assoc(:players, players)
    end
  end
end
