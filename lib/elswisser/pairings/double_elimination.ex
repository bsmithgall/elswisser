defmodule Elswisser.Pairings.DoubleElimination do
  use Ecto.Schema

  alias Elswisser.Pairings.BracketPairing
  alias Elswisser.Repo
  alias Elswisser.Rounds.Round
  alias Elswisser.Pairings.BracketWorker
  alias Elswisser.Tournaments.Tournament
  alias Elswisser.Matches.Match

  @primary_key false
  embedded_schema do
    field :round_number, :integer
    field :winner_round, :integer
    field :winner_match, :integer
    field :loser_round, :integer
    field :loser_match, :integer
    embeds_one :pairing, BracketPairing
  end

  def create_all(%Tournament{} = tournament) do
    players = Enum.sort_by(tournament.players, & &1.rating, :desc)

    with {:ok, decoded} = BracketWorker.generate_bracket(players),
         matches <- Enum.map(decoded, &parse(&1, players, tournament.id)),
         {:ok, rounds_multi} <- make_round_multi(matches, tournament.id) |> Repo.transaction(),
         {:ok, matches_and_games_multi} <-
           make_game_match_multi(matches, rounds_multi) |> Repo.transaction(),
         {:ok, _} <-
           link_matches(matches, rounds_multi, matches_and_games_multi) |> Repo.transaction() do
      {:ok, tournament.id}
    else
      {:error, error} -> {:error, error}
    end
  end

  def parse(m, players, tournament_id) do
    player_one_idx = Enum.find_index(players, &(&1.id == m["player1"]))
    player_two_idx = Enum.find_index(players, &(&1.id == m["player2"]))

    %__MODULE__{
      round_number: m["round"],
      winner_round: if(m["win"], do: m["win"]["round"]),
      winner_match: if(m["win"], do: m["win"]["match"]),
      loser_round: if(m["loss"], do: m["loss"]["round"]),
      loser_match: if(m["loss"], do: m["loss"]["match"]),
      pairing: %BracketPairing{
        tournament_id: tournament_id,
        player_one: if(not is_nil(player_one_idx), do: Enum.at(players, player_one_idx)),
        player_one_seed: if(not is_nil(player_one_idx), do: player_one_idx + 1),
        player_two: if(not is_nil(player_two_idx), do: Enum.at(players, player_two_idx)),
        player_two_seed: if(not is_nil(player_two_idx), do: player_two_idx + 1),
        display_order: m["match"]
      }
    }
  end

  def make_round_multi(matches, tournament_id) do
    Enum.map(matches, & &1.round_number)
    |> Enum.uniq()
    |> Enum.reduce(Ecto.Multi.new(), fn round_number, acc ->
      acc
      |> Ecto.Multi.append(
        Ecto.Multi.new()
        |> Ecto.Multi.insert(
          round_number,
          %Round{}
          |> Round.changeset(%{
            number: round_number,
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
                BracketPairing.to_game_params(de.pairing, round_id)
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
end
