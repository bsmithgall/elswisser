defmodule Elswisser.Pairings.DoubleElimination.Next do
  alias Elswisser.Rounds.Round
  alias Elswisser.Matches
  alias Elswisser.Matches.Match
  alias Elswisser.Games.Game
  alias Elswisser.Repo

  @doc """
  Advances winners and losers from a completed round to their linked matches.

  Groups players by their destination match (winner_to_id/loser_to_id), then creates
  or updates games in those matches. Multiple matches can feed into the same destination,
  so players are collected as lists and passed to `to_changeset/4`.
  """
  def next_pairings(%Round{} = rnd) do
    linked_matches =
      rnd.matches
      |> Enum.flat_map(&[&1.winner_to_id, &1.loser_to_id])
      |> Enum.filter(&(not is_nil(&1)))
      |> Enum.uniq()
      |> Matches.get_by_id()
      |> Enum.map(&{&1.id, &1})
      |> Enum.into(%{})

    {winners, losers} =
      Enum.reduce(rnd.matches, {%{}, %{}}, fn %Match{} = match, {winners_acc, losers_acc} ->
        {
          Map.update(
            winners_acc,
            match.winner_to_id,
            [Match.winner(match)],
            &(&1 ++ [Match.winner(match)])
          ),
          Map.update(
            losers_acc,
            match.loser_to_id,
            [Match.loser(match)],
            &(&1 ++ [Match.loser(match)])
          )
        }
      end)

    winners_changeset =
      winners
      |> Enum.reduce(Ecto.Multi.new(), fn {match_id, players}, acc ->
        acc
        |> Ecto.Multi.append(
          to_changeset(:winner, Map.get(linked_matches, match_id), players, rnd.tournament_id)
        )
      end)

    losers_changeset =
      losers
      |> Enum.reduce(Ecto.Multi.new(), fn {match_id, players}, acc ->
        acc
        |> Ecto.Multi.append(
          to_changeset(:loser, Map.get(linked_matches, match_id), players, rnd.tournament_id)
        )
      end)

    Ecto.Multi.append(winners_changeset, losers_changeset) |> Repo.transaction()
  end

  @doc """
  Generates changesets for advancing players to their next match.

  Handles five cases:
  1. Two players advancing, match has no game yet -> insert new game
  2. Two players advancing, match has existing game -> update existing game
  3. One player advancing, match has no game yet -> insert new game
  4. One player advancing, match has existing game -> update existing game
  5. Match is nil (final match with no onward linkage) -> return empty Multi
  """
  @spec to_changeset(:winner | :loser, %Match{} | nil, list({number(), number()}), number()) ::
          Ecto.Multi.t()

  def to_changeset(tag, %Match{games: []} = match, [{p1, p1_seed}, {p2, p2_seed}], tournament_id) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(
      {tag, :game, match.id},
      %Game{
        tournament_id: tournament_id,
        round_id: match.round_id,
        match_id: match.id
      }
      |> Game.changeset(Game.take_seat(p1, p1_seed, p2, p2_seed))
    )
  end

  def to_changeset(tag, %Match{games: games} = match, [{p1, p1_seed}, {p2, p2_seed}], _) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(
      {tag, :game, match.id},
      hd(games) |> Game.changeset(Game.take_seat(p1, p1_seed, p2, p2_seed))
    )
  end

  def to_changeset(tag, %Match{games: []} = match, [{player, seed}], tournament_id) do
    game = %Game{
      tournament_id: tournament_id,
      round_id: match.round_id,
      match_id: match.id
    }

    Ecto.Multi.new()
    |> Ecto.Multi.insert(
      {tag, :game, match.id},
      Game.changeset(game, Game.take_seat(game, player, seed))
    )
  end

  def to_changeset(tag, %Match{games: games} = match, [{player, seed}], _) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(
      {tag, :game, match.id},
      hd(games)
      |> then(fn %Game{} = game -> Game.changeset(game, Game.take_seat(game, player, seed)) end)
    )
  end

  def to_changeset(_, nil, _, _), do: %Ecto.Multi{}
end
