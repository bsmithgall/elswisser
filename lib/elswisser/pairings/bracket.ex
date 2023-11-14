defmodule Elswisser.Pairings.Bracket do
  alias Elswisser.Pairings.Bye
  alias Elswisser.Tournaments.Tournament

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
end
