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
  def get_round!(id), do: Repo.get!(Round, id)

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
end
