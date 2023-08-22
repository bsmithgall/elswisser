defmodule Elswisser.Rounds do
  @moduledoc """
  The Rounds context.
  """

  import Ecto.Query, warn: false
  alias Elswisser.Repo

  alias Elswisser.Rounds.Round
  alias Elswisser.Games.Game

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

  def get_round_with_games(id) do
    Round.from()
    |> Round.where_id(id)
    |> Round.with_games()
    |> Round.preload_games()
    |> Repo.one()
  end

  def get_round_with_games_and_players!(id) do
    Round.from()
    |> Round.where_id(id)
    |> Round.with_games()
    |> Game.with_white_player()
    |> Game.with_black_player()
    |> Round.preload_games_and_players()
    |> Repo.one!()
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
  Mark all games associated with this round that do not currently have a result
  as a draw.
  """
  def draw_unfinished(id) do
    query =
      Game.from()
      |> Game.where_round_id(id)
      |> Game.where_unfinished()

    Repo.update_all(query, set: [result: 0])
  end
end
