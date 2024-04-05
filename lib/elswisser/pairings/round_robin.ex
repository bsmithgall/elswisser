defmodule Elswisser.Pairings.RoundRobin do
  alias Elswisser.Matches.Match
  alias Elswisser.Repo
  alias Elswisser.Rounds.Round
  alias Elswisser.Pairings.Bye
  alias Elswisser.Tournaments.Tournament

  defguardp even_len?(players) when is_list(players) and rem(length(players), 2) == 0

  @doc """
  The classic round robin algorithm is as follows:

  1. Take all players and partition them in half (if odd # of players, add a bye
     player)
  2. Pair everyone index-wise for the first round
  3. Rotate all players in the original array except for the first player.
  4. Repeat n-1 times.
  5. Once pairings have been made, we have to pick colors. For all players idx and
     jdx, if idx < jdx, idx is white iff (jdx - 1) % 2 == 0
  """
  def create_all(%Tournament{} = tournament) do
    pairings =
      tournament.players
      |> make_pairings()
      |> Enum.shuffle()

    with {:ok, rounds_multi} <-
           make_round_multi(length(pairings), tournament.id) |> Repo.transaction(),
         {:ok, _games_multi} <-
           make_game_match_multi(pairings, rounds_multi, tournament.id) |> Repo.transaction() do
      {:ok, tournament.id}
    else
      {:error, error} -> {:error, error}
    end
  end

  def make_pairings(players) when is_list(players) and even_len?(players) do
    colors = color_grid(length(players) - 1)

    Enum.reduce_while(players, {0, Enum.with_index(players), []}, fn _, {idx, cur, acc} ->
      if idx >= length(players) - 1 do
        {:halt, acc}
      else
        {:cont, {idx + 1, rotate(cur), acc ++ [pairing(cur)]}}
      end
    end)
    |> Enum.map(fn rnd ->
      Enum.map(rnd, fn match -> set_colors(match, colors) end)
    end)
  end

  def make_pairings(players) when is_list(players),
    do: make_pairings([Bye.bye_player() | players])

  def make_round_multi(round_count, tournament_id) do
    1..round_count
    |> Enum.reduce(Ecto.Multi.new(), fn round_number, acc ->
      acc
      |> Ecto.Multi.append(
        Ecto.Multi.new()
        |> Ecto.Multi.insert(
          round_number,
          %Round{}
          |> Round.changeset(%{
            number: round_number,
            tournament_id: tournament_id,
            type: :none,
            display_name: "Round #{round_number}",
            status:
              if round_number == 1 do
                :playing
              else
                :pairing
              end
          })
        )
      )
    end)
  end

  def make_game_match_multi(pairings, rounds, tournament_id) do
    with_round_numbers =
      Enum.with_index(pairings, 1)
      |> Enum.flat_map(fn {pairing, round_number} ->
        Enum.with_index(pairing, 1) |> Enum.map(fn {p, board} -> {p, board, round_number} end)
      end)

    Enum.reduce(with_round_numbers, Ecto.Multi.new(), fn {{p1, p2}, board, round_number}, acc ->
      round_id = Map.get(rounds, round_number).id
      match_multi_id = {round_number, board}

      acc
      |> Ecto.Multi.append(
        Ecto.Multi.new()
        |> Ecto.Multi.insert(
          match_multi_id,
          %Match{}
          |> Match.changeset(%{
            round_id: round_id,
            display_order: board,
            board: board
          })
        )
        |> Ecto.Multi.merge(fn %{^match_multi_id => match} ->
          Ecto.Multi.new()
          |> Ecto.Multi.insert(
            {:game, match_multi_id},
            Ecto.build_assoc(match, :games, %{
              white_id: p1.id,
              white_rating: p1.rating,
              black_id: p2.id,
              black_rating: p2.rating,
              tournament_id: tournament_id,
              round_id: round_id
            })
          )
        end)
      )
    end)
  end

  defp pairing(players) when is_list(players) do
    [top, bottom] = halve(players)
    Enum.zip(top, Enum.reverse(bottom))
  end

  defp rotate([steady | rotates]) do
    {h, t} = rotates |> Enum.split(-1)
    [steady | t ++ h]
  end

  defp halve(players) when is_list(players) do
    Enum.chunk_every(players, length(players) |> div(2))
  end

  defp color_grid(num_players) when is_integer(num_players) do
    for i <- 0..num_players, j <- 0..num_players, i < j, into: %{} do
      if rem(j - i, 2) == 0,
        do: {MapSet.new([i, j]), {j, i}},
        else: {MapSet.new([i, j]), {i, j}}
    end
  end

  defp set_colors({{p1, p1idx}, {p2, p2idx}}, color_grid) do
    lookup = MapSet.new([p1idx, p2idx])
    {white, _} = Map.get(color_grid, lookup)
    if p1idx == white, do: {p1, p2}, else: {p2, p1}
  end
end
