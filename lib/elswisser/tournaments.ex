defmodule Elswisser.Tournaments do
  @moduledoc """
  The Tournaments context.
  """

  import Ecto.Query, warn: false
  alias Elswisser.Repo

  alias Elswisser.Tournaments.Tournament
  alias Elswisser.Players.Player
  alias Elswisser.Rounds.Round

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
    |> Repo.preload(:players)
    |> Repo.preload(:rounds)
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
    |> Tournament.changeset(Map.merge(attrs, %{length: len}))
    |> Ecto.Changeset.put_assoc(:players, players)
    |> Ecto.Changeset.put_assoc(:rounds, rounds)
  end

  def list_players_by_id(player_ids) do
    Repo.all(from p in Player, where: p.id in ^player_ids)
  end

  def calculate_length(players) do
    ceil(Math.log2(length(players)))
  end

  def ensure_rounds(len) do
    Enum.map(1..len, fn n -> %{number: n} end)
  end

  @doc """
  Ensures that there are sufficient rounds if we add a new player and it gets
  pushed over the previous threshold for number of swiss games.
  """
  def ensure_rounds(len, id) do
    max_rounds = Repo.aggregate(from(r in Round, where: r.tournament_id == ^id), :max, :number)

    cond do
      max_rounds < len ->
        Enum.map((max_rounds + 1)..len, fn n ->
          %{tournament_id: id, number: n}
        end)

      true ->
        []
    end
  end
end
