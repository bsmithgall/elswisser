defmodule Elswisser.Tournaments do
  @moduledoc """
  The Tournaments context.
  """

  import Ecto.Query, warn: false
  require Elswisser.Tournaments.Tournament
  alias Elswisser.Pairings.RoundRobin
  alias Elswisser.Pairings.DoubleElimination
  alias Elswisser.Tournaments.TournamentPlayer
  alias Elswisser.Matches.Match
  alias Elswisser.Matches
  alias Elswisser.Pairings.BracketPairing
  alias Elswisser.Repo

  alias Elswisser.Tournaments.Tournament
  alias Elswisser.Rounds
  alias Elswisser.Rounds.Round
  alias Elswisser.Games.Game

  @doc """
  Returns the list of tournaments.

  ## Examples

      iex> list_tournaments()
      [%Tournament{}, ...]

  """
  def list_tournaments do
    Tournament |> Tournament.most_recent_first() |> Repo.all()
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
    Tournament.from() |> Tournament.where_id(id) |> Repo.one!()
  end

  def get_tournament(id) do
    Tournament.from() |> Tournament.where_id(id) |> Repo.one()
  end

  def get_tournament_with_rounds(id) do
    Tournament.from()
    |> Tournament.where_id(id)
    |> Tournament.with_rounds()
    |> Tournament.preload_rounds()
    |> Repo.one()
  end

  def get_tournament_with_players!(id) do
    Tournament.from()
    |> Tournament.where_id(id)
    |> Tournament.with_players()
    |> Tournament.preload_players()
    |> Repo.one()
  end

  def get_tournament_with_rounds_and_players(id) do
    Tournament.from()
    |> Tournament.where_id(id)
    |> Tournament.with_players()
    |> Tournament.with_rounds()
    |> Tournament.preload_players()
    |> Tournament.preload_rounds()
    |> Repo.one()
  end

  def get_tournament_with_all(id) do
    Tournament.from()
    |> Tournament.where_id(id)
    |> Tournament.with_players()
    |> Tournament.with_rounds()
    |> Round.with_matches()
    |> Round.order_by_number()
    |> Match.with_games()
    |> Game.with_both_players()
    |> Tournament.preload_all()
    |> Repo.one()
  end

  def get_tournament_players(id) do
    TournamentPlayer.from()
    |> TournamentPlayer.where_tournament_id(id)
    |> Repo.all()
  end

  def current_round(%Tournament{} = tournament) when is_map_key(tournament, :rounds) do
    case tournament.rounds do
      %Ecto.Association.NotLoaded{} -> %Round{number: 0}
      rnds when is_list(rnds) and length(rnds) == 0 -> %Round{number: 0}
      _ -> Enum.max_by(tournament.rounds, fn r -> r.number end)
    end
  end

  def current_round(%Tournament{} = tournament) when not is_map_key(tournament, :rounds) do
    %{number: 0}
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
  Returns an `%Ecto.Changeset{}` for tracking tournament changes. If a length is
  explicitly set, use that. Otherwise calculate it based on the number of players.

  ## Examples

      iex> change_tournament(tournament)
      %Ecto.Changeset{data: %Tournament{}}

  """
  def change_tournament(tournament, attrs \\ %{})

  def change_tournament(%Tournament{} = tournament, attrs)
      when not is_map_key(attrs, :length) do
    atoms = ensure_atom(attrs)
    type = if is_nil(tournament.type), do: Map.get(atoms, :type), else: tournament.type

    players =
      Elswisser.Players.list_by_id(atoms[:player_ids])
      |> TournamentPlayer.from_players(tournament.id, Tournament.knockout?(type))

    len = calculate_length(players, type)

    tournament
    |> Repo.preload(:players)
    |> Repo.preload(:rounds)
    |> Tournament.changeset(atoms |> Map.merge(%{length: len}))
    |> maybe_put_players(players)
  end

  def change_tournament(%Tournament{} = tournament, attrs)
      when is_map_key(attrs, :length) do
    players =
      Elswisser.Players.list_by_id(ensure_atom(attrs)[:player_ids])
      |> TournamentPlayer.from_players(tournament.id, Tournament.knockout?(tournament))

    tournament
    |> Repo.preload(:players)
    |> Repo.preload(:rounds)
    |> Tournament.changeset(attrs)
    |> maybe_put_players(players)
  end

  def create_next_round(%Tournament{} = tournament, current_round_number)
      when is_binary(current_round_number) do
    create_next_round(tournament, String.to_integer(current_round_number))
  end

  def create_next_round(%Tournament{length: len}, current_round_number)
      when current_round_number >= len,
      do: :finished

  @doc """
  Attempt to create the next round for a tournament. If the next round number is
  > than the tournament's length, return :completed, otherwise return :ok or
  > :error based on the results from Ecto.
  """
  def create_next_round(%Tournament{type: :swiss} = tournament, current_round_number) do
    Rounds.create_round(%{
      tournament_id: tournament.id,
      number: current_round_number + 1,
      status: :pairing
    })
  end

  def create_next_round(%Tournament{type: :single_elimination} = tournament, 0) do
    {:ok, rnd} =
      Rounds.create_round(%{
        tournament_id: tournament.id,
        number: 1,
        status: :playing
      })

    BracketPairing.rating_based_pairings(tournament)
    |> Enum.map(&BracketPairing.assign_colors/1)
    # re-sort here to get the proper board numbers
    |> Enum.sort_by(&BracketPairing.max_player_rating/1, :desc)
    |> Enum.map(&BracketPairing.to_game_params(&1, rnd.id))
    |> Matches.create_matches_from_games()

    {:ok, rnd}
  end

  def create_next_round(%Tournament{type: :single_elimination} = tournament, current_round_number) do
    {:ok, rnd} =
      Rounds.create_round(%{
        tournament_id: tournament.id,
        number: current_round_number + 1,
        status: :playing
      })

    Rounds.get_round_with_matches_and_players(tournament.id, current_round_number)
    |> BracketPairing.next_matchups(:winners)
    |> Enum.map(&BracketPairing.assign_colors/1)
    |> Enum.sort_by(&BracketPairing.max_player_rating/1, :desc)
    |> Enum.map(&BracketPairing.to_game_params(&1, rnd.id))
    |> Matches.create_matches_from_games()

    # get all the matches and games from the just finished round

    {:ok, rnd}
  end

  def create_next_round(%Tournament{type: :double_elimination} = tournament, 0) do
    {:ok, _} = DoubleElimination.create_all(tournament)

    {:ok, %{tournament_id: tournament.id}}
  end

  # everything is aleady created here
  def create_next_round(%Tournament{type: :double_elimination} = tournament, current_round_number) do
    {:ok, _} =
      Rounds.get_round_with_matches_and_players(tournament.id, current_round_number)
      |> DoubleElimination.next_pairings()

    {:ok, %{tournament_id: tournament.id}}
  end

  def create_next_round(%Tournament{type: :round_robin} = tournament, 0) do
    {:ok, _} = RoundRobin.create_all(tournament)

    {:ok, %{tournament_id: tournament.id}}
  end

  def create_next_round(%Tournament{type: :round_robin} = tournament, current_round_number) do
    Rounds.get_next_round(tournament.id, current_round_number) |> Rounds.set_playing()
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
      where: p.id != -1,
      select: {p, t.tournament_id}
    )
    |> Repo.all()
    |> Enum.map(fn {p, tid} -> Map.merge(p, %{in_tournament: !is_nil(tid)}) end)
    |> Enum.split_with(fn p -> p.in_tournament end)
  end

  def calculate_length(players, _type) when length(players) == 0 do
    0
  end

  def calculate_length(players, type) when is_binary(type),
    do: calculate_length(players, String.to_atom(type))

  def calculate_length(players, type)
      when is_list(players) and type in ~w[swiss single_elimination]a do
    players |> length() |> Math.log(2) |> ceil()
  end

  def calculate_length(players, :double_elimination) when is_list(players) do
    wb = players |> length() |> Math.log(2) |> ceil()
    lb = wb + (wb |> Math.log(2) |> ceil())

    wb + lb + 1
  end

  def calculate_length(players, :round_robin) when is_list(players) do
    if rem(length(players), 2) == 0, do: length(players) - 1, else: length(players)
  end

  def calculate_length(_, _), do: 0

  defp ensure_atom(attrs) when is_map(attrs) do
    Enum.reduce(attrs, %{}, fn
      {key, value}, acc when is_atom(key) -> Map.put(acc, key, value)
      {key, value}, acc when is_binary(key) -> Map.put(acc, String.to_existing_atom(key), value)
    end)
  end

  defp maybe_put_players(changeset, tournament_players) do
    if Enum.empty?(tournament_players) do
      changeset
    else
      changeset |> Ecto.Changeset.put_assoc(:tournament_players, tournament_players)
    end
  end
end
