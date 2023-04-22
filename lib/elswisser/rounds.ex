defmodule Elswisser.Rounds do
  @moduledoc """
  The Rounds context.
  """

  import Ecto.Query, warn: false
  alias Elswisser.Repo

  alias Elswisser.Rounds.Round
  alias Elswisser.Rounds.Game

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

  def add_game(%Round{} = r, game_attrs) do
    %Game{round_id: r.id}
    |> Game.changeset(game_attrs)
    |> Ecto.Changeset.put_assoc(:round, r)
    |> Repo.insert()
  end

  def get_game!(id) do
    Repo.get!(Game, id)
  end

  def get_games_for_round!(id) do
    Repo.all(
      from g in Game,
        left_join: w in Elswisser.Players.Player,
        on: g.white == w.id,
        left_join: b in Elswisser.Players.Player,
        on: g.black == b.id,
        where: g.round_id == ^id,
        select: {g, w, b}
    )
    |> Enum.map(fn {g, w, b} -> %{id: g.id, game: g, white: w, black: b} end)
  end

  def update_game(%Game{} = game, attrs) do
    game |> Game.changeset(attrs) |> Repo.update()
  end
end
