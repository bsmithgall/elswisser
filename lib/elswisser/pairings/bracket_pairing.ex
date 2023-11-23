defmodule Elswisser.Pairings.BracketPairing do
  use Ecto.Schema

  alias Elswisser.Pairings.Seed
  alias Elswisser.Players.Player
  alias Elswisser.Pairings.Bye
  alias Elswisser.Tournaments.Tournament

  @primary_key false
  embedded_schema do
    embeds_one :player_one, Player
    embeds_one :player_two, Player
    field :display_order, :integer
    field :tournament_id, :integer
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
  def rating_based_pairings(%Tournament{} = tournament) do
    sorted = Enum.sort_by(tournament.players, & &1.rating, :desc)
    size = next_power_of_two(sorted)

    all_players = Enum.concat(sorted, List.duplicate(Bye.bye_player(), size - length(sorted)))

    Seed.seed(all_players)
    |> Enum.with_index()
    |> Enum.map(fn {{l, r}, idx} ->
      %__MODULE__{
        player_one: l,
        player_two: r,
        tournament_id: tournament.id,
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

  def to_game_params(%__MODULE__{} = pairing, round_id) do
    %{
      white_id: pairing.player_one.id,
      white_rating: pairing.player_one.rating,
      black_id: pairing.player_two.id,
      black_rating: pairing.player_two.rating,
      tournament_id: pairing.tournament_id,
      round_id: round_id,
      display_order: pairing.display_order
    }
  end

  def assign_colors(%__MODULE__{} = pairing) do
    if :rand.uniform() > 0.5,
      do:
        Map.merge(pairing, %{
          player_one: pairing.player_two,
          player_two: pairing.player_one
        }),
      else: pairing
  end
end
