defmodule Elswisser.Pairings.BracketPairing do
  use Ecto.Schema

  alias Elswisser.Players.Player
  alias Elswisser.Pairings.Bye
  alias Elswisser.Tournaments.Tournament

  @primary_key false
  embedded_schema do
    embeds_one :player_one, Player
    embeds_one :player_two, Player
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

    {byes, to_pair} = partition(sorted)

    byes
    |> Enum.map(&{&1, Bye.bye_player()})
    |> Enum.concat(
      to_pair
      |> Enum.reduce_while([], fn t, acc ->
        if length(acc) == length(to_pair) / 2 do
          {:halt, acc}
        else
          {:cont, [{t, Enum.at(to_pair, -length(acc) - 1)} | acc]}
        end
      end)
      |> Enum.reverse()
    )
    |> Enum.map(fn {l, r} ->
      %__MODULE__{player_one: l, player_two: r, tournament_id: tournament.id}
    end)
  end

  def next_power_of_two(n) when is_number(n) do
    Math.pow(2, ceil(Math.log(n, 2)))
  end

  def next_power_of_two(n) when is_list(n) do
    next_power_of_two(length(n))
  end

  def partition(players) do
    Enum.split(players, next_power_of_two(players) - length(players))
  end

  def to_game_params(%__MODULE__{} = pairing, round_id) do
    %{
      white_id: pairing.player_one.id,
      white_rating: pairing.player_one.rating,
      black_id: pairing.player_two.id,
      black_rating: pairing.player_two.rating,
      tournament_id: pairing.tournament_id,
      round_id: round_id
    }
  end

  def assign_colors(%__MODULE__{} = pairing) do
    if :rand.uniform() > 0.5,
      do: %__MODULE__{
        player_one: pairing.player_two,
        player_two: pairing.player_one,
        tournament_id: pairing.tournament_id
      },
      else: pairing
  end
end
