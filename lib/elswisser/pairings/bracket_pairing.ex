defmodule Elswisser.Pairings.BracketPairing do
  use Ecto.Schema

  require Elswisser.Pairings.Bye
  alias Elswisser.Matches.Match
  alias Elswisser.Games.Game
  alias Elswisser.Pairings.Seed
  alias Elswisser.Players.Player
  alias Elswisser.Pairings.Bye
  alias Elswisser.Tournaments.Tournament
  alias Elswisser.Rounds.Round

  @primary_key false
  embedded_schema do
    embeds_one :player_one, Player
    field :player_one_seed, :integer
    embeds_one :player_two, Player
    field :player_two_seed, :integer
    field :display_order, :integer
    field :tournament_id, :integer
    field :result, :integer
  end

  @doc """
  Generates rating-based {player1, player2} pairings based on a tournament's
  roster. In general, this works as follows:

  1. Find the next-largest power-of-two value compared to the number of players.
  2. Fill in byes as appropriate. To do this take the total number of players,
     and slice off the bottom N players, where N is the previous power of two.
  3. Give the top N players byes
  4. Match all remaining players together with the highest playing the lowest

  """
  def rating_based_pairings(%Tournament{players: []} = _tournament), do: []

  def rating_based_pairings(%Tournament{} = tournament) do
    sorted = Enum.sort_by(tournament.players, & &1.rating, :desc)
    size = next_power_of_two(sorted)

    all_players = Enum.concat(sorted, List.duplicate(Bye.bye_player(), size - length(sorted)))

    Seed.seed(all_players)
    |> Enum.with_index()
    |> Enum.map(fn {{l, r}, idx} ->
      %__MODULE__{
        player_one: l,
        player_one_seed: find_seed(sorted, l),
        player_two: r,
        player_two_seed: find_seed(sorted, r),
        tournament_id: tournament.id,
        display_order: idx
      }
    end)
  end

  @doc """
  Given a round (with matches, games, and players preloaded), calculate matches for the
  next round.
  """
  def next_matchups(%Round{} = rnd, :winners) do
    rnd.matches
    |> Enum.chunk_every(2)
    |> Enum.with_index()
    |> Enum.map(fn {[l, r], idx} ->
      {{one, one_seed}, _} = Match.result(l)
      {{two, two_seed}, _} = Match.result(r)

      %__MODULE__{
        player_one: one,
        player_one_seed: one_seed,
        player_two: two,
        player_two_seed: two_seed,
        tournament_id: rnd.tournament_id,
        display_order: idx
      }
    end)
  end

  def next_power_of_two(n) when is_number(n) do
    Math.pow(2, ceil(Math.log(n, 2)))
  end

  def next_power_of_two(n) when is_list(n) do
    next_power_of_two(length(n))
  end

  def to_match_changeset(%__MODULE__{} = pairing, round_id, board \\ nil) do
    %Match{}
    |> Match.changeset(%{
      display_order: display_order(board, pairing.display_order),
      board: board(board, pairing.display_order),
      round_id: round_id,
      player_one_id: if(pairing.player_one, do: pairing.player_one.id),
      player_two_id: if(pairing.player_two, do: pairing.player_two.id),
      player_one_seed: pairing.player_one_seed,
      player_two_seed: pairing.player_two_seed
    })
  end

  def to_game_changeset(%__MODULE__{} = pairing, round_id) do
    %Game{}
    |> Game.changeset(%{
      white_id: pairing.player_one.id,
      white_rating: pairing.player_one.rating,
      black_id: pairing.player_two.id,
      black_rating: pairing.player_two.rating,
      tournament_id: pairing.tournament_id,
      round_id: round_id
    })
  end

  def to_game_params(%__MODULE__{} = pairing, round_id) do
    base = %{
      white_id: if(pairing.player_one, do: pairing.player_one.id),
      white_rating: if(pairing.player_one, do: pairing.player_one.rating),
      black_id: if(pairing.player_two, do: pairing.player_two.id),
      black_rating: if(pairing.player_two, do: pairing.player_two.rating),
      tournament_id: pairing.tournament_id,
      round_id: round_id
    }

    if base.black_id == Bye.bye_player().id, do: base |> Map.merge(%{result: 1}), else: base
  end

  def assign_colors(%__MODULE__{player_two: player_two} = pairing)
      when Bye.bye_player?(player_two),
      do: pairing

  def assign_colors(%__MODULE__{} = pairing) do
    if :rand.uniform() > 0.5,
      do:
        Map.merge(pairing, %{
          player_one: pairing.player_two,
          player_one_seed: pairing.player_two_seed,
          player_two: pairing.player_one,
          player_two_seed: pairing.player_one_seed
        }),
      else: pairing
  end

  def max_player_rating(%__MODULE__{} = pairing) do
    max(pairing.player_one.rating, pairing.player_two.rating)
  end

  defp find_seed(_sorted, %Player{id: -1} = _player), do: nil

  defp find_seed(sorted, %Player{} = player) do
    idx = sorted |> Enum.find_index(&(&1 == player))
    idx + 1
  end

  defp board(board, display_order) do
    if is_nil(board), do: display_order, else: board
  end

  defp display_order(board, display_order) do
    if is_nil(display_order), do: board, else: display_order
  end
end
