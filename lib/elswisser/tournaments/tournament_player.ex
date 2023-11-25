defmodule Elswisser.Tournaments.TournamentPlayer do
  use Ecto.Schema
  import Ecto.Query, warn: false
  import Ecto.Changeset

  alias __MODULE__

  schema "tournament_players_v2" do
    belongs_to :player, Elswisser.Players.Player
    belongs_to :tournament, Elswisser.Tournaments.Tournament

    field :seed, :integer
  end

  def changeset(%TournamentPlayer{} = tournament_player, attrs) do
    tournament_player
    |> cast(attrs, [:player_id, :tournament_id, :seed])
    |> validate_required([:player_id, :tournament_id])
  end

  def from() do
    from(tp in TournamentPlayer, as: :tournament_player)
  end

  def where_tournament_id(query, id) do
    from([tournament_player: tp] in query, where: tp.tournament_id == ^id)
  end

  def from_players(players, tournament_id) when is_list(players) do
    players
    |> Enum.map(fn p ->
      %TournamentPlayer{
        tournament_id: tournament_id,
        player_id: p.id
      }
    end)
  end

  def from_players(players, tournament_id, false), do: from_players(players, tournament_id)

  def from_players(players, tournament_id, true) when is_list(players) do
    players
    |> Enum.sort_by(& &1.rating, :desc)
    |> Enum.with_index(1)
    |> Enum.map(fn {p, idx} ->
      %TournamentPlayer{
        tournament_id: tournament_id,
        player_id: p.id,
        seed: idx
      }
    end)
  end
end
