defmodule Elswisser.Pairings.DoubleElimination do
  use Ecto.Schema

  alias Elswisser.Games.Game
  alias Elswisser.Matches
  alias Elswisser.Matches.Match
  alias Elswisser.Pairings.BracketPairing
  alias Elswisser.Pairings.BracketWorker
  alias Elswisser.Pairings.Bye
  alias Elswisser.Repo
  alias Elswisser.Rounds.Round
  alias Elswisser.Tournaments.Tournament

  @primary_key false
  embedded_schema do
    field :round_number, :integer
    field :round_type, :string
    field :winner_round, :integer
    field :winner_match, :integer
    field :loser_round, :integer
    field :loser_match, :integer
    embeds_one :pairing, BracketPairing
  end

  def create_all(%Tournament{} = tournament) do
    players = Enum.sort_by(tournament.players, & &1.rating, :desc)
    size = BracketPairing.next_power_of_two(players)

    byes = -1..(-1 * (size - length(players)))//-1 |> Enum.map(&Bye.bye_player(&1))

    with {:ok, raw_matches, rounds} <- BracketWorker.generate_bracket(players ++ byes),
         matches <- Enum.map(raw_matches, &parse(&1, players, tournament.id)),
         {:ok, rounds_multi} <-
           make_round_multi(matches, rounds, tournament.id) |> Repo.transaction(),
         {:ok, matches_and_games_multi} <-
           make_game_match_multi(matches, rounds_multi) |> Repo.transaction(),
         {:ok, _} <-
           link_matches(matches, rounds_multi, matches_and_games_multi) |> Repo.transaction() do
      {:ok, tournament.id}
    else
      {:error, error} -> {:error, error}
    end
  end

  def next_pairings(rnd) do
    linked_matches =
      Enum.flat_map(rnd.matches, &[&1.winner_to_id, &1.loser_to_id])
      |> Enum.filter(&(not is_nil(&1)))
      |> Enum.uniq()
      |> Matches.get_by_id()
      |> Enum.map(&{&1.id, &1})
      |> Enum.into(%{})

    winners_to =
      Enum.reduce(rnd.matches, %{}, fn match, acc ->
        Map.update(acc, match.winner_to_id, [Match.winner(match)], &(&1 ++ [Match.winner(match)]))
      end)
      |> Enum.reduce(Ecto.Multi.new(), fn {k, v}, acc ->
        acc
        |> Ecto.Multi.append(
          generate_changeset(:winner, Map.get(linked_matches, k), v, rnd.tournament_id)
        )
      end)

    losers_to =
      Enum.reduce(rnd.matches, %{}, fn match, acc ->
        Map.update(acc, match.loser_to_id, [Match.loser(match)], &(&1 ++ [Match.loser(match)]))
      end)
      |> Enum.reduce(Ecto.Multi.new(), fn {k, v}, acc ->
        acc
        |> Ecto.Multi.append(
          generate_changeset(:loser, Map.get(linked_matches, k), v, rnd.tournament_id)
        )
      end)

    Ecto.Multi.append(winners_to, losers_to) |> Repo.transaction()
  end

  def parse(m, players, tournament_id) do
    {player_one_seed, player_one} = find_player(m["player1"], players)
    {player_two_seed, player_two} = find_player(m["player2"], players)

    %__MODULE__{
      round_number: m["round"],
      round_type: m["round_type"],
      winner_round: if(m["win"], do: m["win"]["round"]),
      winner_match: if(m["win"], do: m["win"]["match"]),
      loser_round: if(m["loss"], do: m["loss"]["round"]),
      loser_match: if(m["loss"], do: m["loss"]["match"]),
      pairing: %BracketPairing{
        tournament_id: tournament_id,
        player_one: player_one,
        player_one_seed: player_one_seed,
        player_two: player_two,
        player_two_seed: player_two_seed,
        display_order: m["match"]
      }
    }
  end

  def make_round_multi(matches, rounds, tournament_id) do
    Enum.map(matches, &{&1.round_number, &1.round_type})
    |> Enum.uniq()
    |> Enum.reduce(Ecto.Multi.new(), fn {round_number, round_type}, acc ->
      acc
      |> Ecto.Multi.append(
        Ecto.Multi.new()
        |> Ecto.Multi.insert(
          round_number,
          %Round{}
          |> Round.changeset(%{
            number: round_number,
            type: round_type,
            display_name: Map.get(rounds, round_number),
            status: :playing,
            tournament_id: tournament_id
          })
        )
      )
    end)
  end

  def make_game_match_multi(de_matches, rounds_multi) do
    Enum.reduce(de_matches, Ecto.Multi.new(), fn de, acc ->
      round_id = Map.get(rounds_multi, de.round_number).id

      match_changeset = BracketPairing.to_match_changeset(de.pairing, round_id)
      match_multi_id = {de.round_number, round_id, de.pairing.display_order}

      match_multi =
        Ecto.Multi.new()
        |> Ecto.Multi.insert(match_multi_id, match_changeset)

      match_multi =
        if has_game?(de) do
          Ecto.Multi.merge(match_multi, fn %{^match_multi_id => match} ->
            Ecto.Multi.new()
            |> Ecto.Multi.insert(
              {:game, match_multi_id},
              Ecto.build_assoc(
                match,
                :games,
                de.pairing
                |> BracketPairing.assign_colors()
                |> BracketPairing.to_game_params(round_id)
              )
            )
          end)
        else
          match_multi
        end

      acc |> Ecto.Multi.append(match_multi)
    end)
  end

  def link_matches(de_matches, rounds_multi, matches_and_games_multi) do
    Enum.reduce(de_matches, Ecto.Multi.new(), fn de, acc ->
      current_match =
        Map.get(
          matches_and_games_multi,
          {de.round_number, Map.get(rounds_multi, de.round_number).id, de.pairing.display_order}
        )

      next_matches =
        %{}
        |> Map.merge(
          if(is_nil(de.winner_round),
            do: %{},
            else: %{
              winner_to_id:
                Map.get(
                  matches_and_games_multi,
                  {de.winner_round, Map.get(rounds_multi, de.winner_round).id, de.winner_match}
                ).id
            }
          )
        )
        |> Map.merge(
          if(is_nil(de.loser_round),
            do: %{},
            else: %{
              loser_to_id:
                Map.get(
                  matches_and_games_multi,
                  {de.loser_round, Map.get(rounds_multi, de.loser_round).id, de.loser_match}
                ).id
            }
          )
        )

      acc
      |> Ecto.Multi.append(
        Ecto.Multi.new()
        |> Ecto.Multi.update(
          {:match, current_match.id},
          Match.changeset(current_match, next_matches)
        )
      )
    end)
  end

  defp has_game?(%__MODULE__{} = de) do
    [de.pairing.player_one, de.pairing.player_two] |> Enum.any?()
  end

  def generate_changeset(_, nil, _, _), do: %Ecto.Multi{}

  def generate_changeset(
        tag,
        %Match{games: []} = match,
        [{player_one, player_one_seed}, {player_two, player_two_seed}],
        tournament_id
      ) do
    Ecto.Multi.insert(
      Ecto.Multi.new(),
      {tag, :game, match.id},
      %Game{}
      |> Game.changeset(
        Map.merge(Game.take_seat(player_one, player_one_seed, player_two, player_two_seed), %{
          tournament_id: tournament_id,
          round_id: match.round_id,
          match_id: match.id
        })
      )
    )
  end

  def generate_changeset(
        tag,
        %Match{} = match,
        [{player_one, player_one_seed}, {player_two, player_two_seed}],
        _
      ) do
    Ecto.Multi.update(
      Ecto.Multi.new(),
      {tag, :game, match.id},
      match.games
      |> hd()
      |> then(fn game ->
        Game.changeset(
          game,
          Game.take_seat(player_one, player_one_seed, player_two, player_two_seed)
        )
      end)
    )
  end

  def generate_changeset(tag, %Match{games: []} = match, [{player, seed}], tournament_id) do
    Ecto.Multi.insert(
      Ecto.Multi.new(),
      {tag, :game, match.id},
      %Game{}
      |> Game.changeset(
        Map.merge(
          Game.take_seat(%Game{}, player, seed),
          %{
            tournament_id: tournament_id,
            round_id: match.round_id,
            match_id: match.id
          }
        )
      )
    )
  end

  def generate_changeset(tag, %Match{} = match, [{player, seed}], _) do
    Ecto.Multi.update(
      Ecto.Multi.new(),
      {tag, :game, match.id},
      match.games
      |> hd()
      |> then(fn game -> Game.changeset(game, Game.take_seat(game, player, seed)) end)
    )
  end

  defp find_player(id, _) when id < 0, do: {nil, Bye.bye_player()}

  defp find_player(id, players) do
    idx = players |> Enum.find_index(&(&1.id == id))
    if is_nil(idx), do: {nil, nil}, else: {idx + 1, Enum.at(players, idx)}
  end
end
