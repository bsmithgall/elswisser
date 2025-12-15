defmodule Elswisser.Rounds do
  @moduledoc """
  The Rounds context.
  """

  import Ecto.Query, warn: false
  alias Elswisser.Matches.Match
  alias Ecto.Multi
  alias Elswisser.Repo

  alias Elswisser.Tournaments
  alias Elswisser.Tournaments.Tournament
  alias Elswisser.Rounds.Round
  alias Elswisser.Rounds.Stats
  alias Elswisser.Games.Game
  alias Elswisser.Players
  alias Elswisser.Players.Player
  alias Elswisser.Players.ELO
  alias Elswisser.Pairings.Bye

  @doc """
  Gets a single round.

  Raises `Ecto.NoResultsError` if the Round does not exist.

  ## Examples

      iex> get_round!(123)
      %Round{}

      iex> get_round!(456)
      ** (Ecto.NoResultsError)

  """
  def get_round!(id) do
    Repo.get!(Round, id)
  end

  def get_round(id) do
    Round.from() |> Round.where_id(id) |> Repo.one()
  end

  def get_next_round(tournament_id, current_round_number) do
    Round.from()
    |> Round.where_tournament_id(tournament_id)
    |> Round.where_round_number(current_round_number + 1)
    |> Repo.one()
  end

  def get_round_with_games(id) do
    Round.from()
    |> Round.where_id(id)
    |> Round.with_games()
    |> Round.preload_games()
    |> Repo.one()
  end

  def get_round_with_matches_and_players!(id) do
    Round.from()
    |> Round.where_id(id)
    |> Round.with_matches()
    |> Match.with_players()
    |> Match.with_games()
    |> Game.with_white_player()
    |> Game.with_black_player()
    |> Round.preload_all()
    |> Repo.one!()
  end

  def get_round_with_matches_and_players(tournament_id, number) do
    Round.from()
    |> Round.where_tournament_id(tournament_id)
    |> Round.where_round_number(number)
    |> Round.with_matches()
    |> Match.with_players()
    |> Match.order_by_display_number()
    |> Match.with_games()
    |> Game.with_white_player()
    |> Game.with_black_player()
    |> Round.preload_all()
    |> Repo.one()
  end

  @doc """
  For a given tournament_id and round_id, find all players that have yet to be
  paired into a game together.
  """
  def get_unpaired_players(round_id, tournament_id) do
    white_games =
      Game.from()
      |> Game.where_round_id(round_id)
      |> Game.select_white_id()

    black_games =
      Game.from()
      |> Game.where_round_id(round_id)
      |> Game.select_black_id()

    all_games = white_games |> union(^black_games)

    Player.from()
    |> Player.where_tournament_id(tournament_id)
    |> Player.where_not_matching(all_games)
    |> Repo.all()
  end

  def get_stats_for_tournament(tournament_id) do
    round_stats =
      Round.from()
      |> Round.where_tournament_id(tournament_id)
      |> Round.with_games()
      |> Game.with_both_players()
      |> Game.where_finished()
      |> Stats.compute()
      |> Round.order_by_number()
      |> Repo.all()

    tournament_stats =
      Enum.reduce(round_stats, %Stats{}, fn %Stats{} = stat, acc ->
        Stats.combine(acc, stat)
      end)

    opening_stats =
      Game.from()
      |> Game.where_tournament_id(tournament_id)
      |> Game.where_finished()
      |> Elswisser.Tournaments.Stats.top_openings(tournament_id)
      |> Repo.all()

    {round_stats, tournament_stats, opening_stats}
  end

  def update_ratings_after_round(id) do
    rnd_with_games = get_round_with_games(id)

    player_ids =
      Enum.reduce(rnd_with_games.games, MapSet.new(), fn g, acc ->
        put_id(acc, g.white_id) |> put_id(g.black_id)
      end)
      |> MapSet.to_list()

    with_k_factors = Players.with_k_factor(player_ids)

    rnd_with_games.games
    |> Enum.filter(fn g ->
      g.white_id != Bye.bye_player_id() and g.black_id != Bye.bye_player_id()
    end)
    |> Enum.reduce(Multi.new(), fn g, multi ->
      {white, white_recalcs} = with_k_factors[g.white_id]
      {black, black_recalcs} = with_k_factors[g.black_id]

      {{new_white, white_change}, {new_black, black_change}} =
        ELO.recalculate(white_recalcs, black_recalcs, g.result)

      white_changeset = Player.changeset(white, %{rating: new_white})
      black_changeset = Player.changeset(black, %{rating: new_black})

      game_changeset =
        Game.changeset(g, %{white_rating_change: white_change, black_rating_change: black_change})

      Multi.update(multi, {:rating, g.white_id}, white_changeset)
      |> Multi.update({:rating, g.black_id}, black_changeset)
      |> Multi.update({:game_rating_change, g.id}, game_changeset)
    end)
    |> Repo.transaction()
  end

  @doc """
  Creates a round.

  ## Examples

      iex> create_round(%{field: value})
      {:ok, %Round{}}

      iex> create_round(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_round(attrs \\ %{}) do
    %Round{}
    |> Round.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a round.

  ## Examples

      iex> update_round(round, %{field: new_value})
      {:ok, %Round{}}

      iex> update_round(round, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_round(%Round{} = round, attrs) do
    round
    |> Round.changeset(attrs)
    |> Repo.update()
  end

  def set_pairing(%Round{} = round) do
    round |> Round.changeset(%{status: :pairing}) |> Repo.update()
  end

  def set_playing(%Round{} = round) do
    round |> Round.changeset(%{status: :playing}) |> Repo.update()
  end

  def set_playing(id) when is_integer(id) do
    get_round!(id) |> update_round(%{status: :playing})
  end

  def set_complete(%Round{} = round) do
    round |> Round.changeset(%{status: :complete}) |> Repo.update()
  end

  def set_complete(id) when is_integer(id) do
    get_round!(id) |> update_round(%{status: :complete})
  end

  def add_game(%Round{} = r, game_attrs) do
    %Game{}
    |> Game.changeset(game_attrs)
    |> Ecto.Changeset.put_assoc(:round, r)
    |> Repo.insert()
  end

  @doc """
  Ensures all matches in a round are complete according to tournament rules.

  For multi-game matches (best_of or first_to formats), this checks that each
  match has reached its completion condition based on the tournament configuration.
  For single-game matches (points_to_win: 1), this is equivalent to checking
  all games are finished.

  Returns `{:ok, 0}` if all matches are complete, or `{:error, message}` with
  the count of incomplete matches.
  """
  def ensure_matches_complete(round_id, %Tournament{} = tournament) do
    incomplete_count =
      Match.from()
      |> Match.where_round_id(round_id)
      |> Match.with_games()
      |> Game.with_both_players()
      |> Match.preload_games_and_players()
      |> Repo.all()
      |> Enum.reject(&Match.complete?(&1, tournament))
      |> length()

    case incomplete_count do
      0 -> {:ok, 0}
      n -> {:error, "#{n} match(es) not complete yet!"}
    end
  end

  @doc """
  Ensure that the bye game actually has a result
  """
  def ensure_bye_set(id) do
    case Game.from() |> Game.where_round_id(id) |> Game.where_bye() |> Repo.one() do
      nil -> {:ok, nil}
      game -> Game.changeset(game, %{result: 0}) |> Repo.update()
    end
  end

  @doc """
  Finalize a round by

  1. Ensuring that all matches are complete for the round according to tournament rules
  2. Update all of the ELOs for each player based on the game results
  3. Set the round as complete
  4. Create the next round of the tournament.
  """
  def finalize_round(%Round{} = rnd, %Tournament{} = tournament) do
    with {:ok, _} <- ensure_bye_set(rnd.id),
         {:ok, _} <- ensure_matches_complete(rnd.id, tournament),
         {:ok, _update} <- update_ratings_after_round(rnd.id),
         {:ok, rnd} <- set_complete(rnd),
         {:ok, next_round} <- Tournaments.create_next_round(tournament, rnd.number) do
      {:ok, next_round}
    else
      :finished -> :finished
      {:error, reason} -> {:error, reason}
    end
  end

  defp put_id(set, -1), do: set
  defp put_id(set, player_id), do: MapSet.put(set, player_id)
end
