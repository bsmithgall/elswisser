defmodule Elswisser.Pairings.DoubleElimination.Create do
  alias Elswisser.Pairings.BracketPairing
  alias Elswisser.Repo
  alias Elswisser.Pairings.DoubleElimination.Rounds
  alias Elswisser.Tournaments.Tournament
  alias Elswisser.Rounds.Round
  alias Elswisser.Matches.Match
  alias Elswisser.Pairings.DoubleElimination.MatchGraph

  @doc """
  Turn a MatchGraph into something the database understands.
  """
  def create_all(%Tournament{} = tournament) do
    with matches <-
           MatchGraph.generate(tournament.players) |> MatchGraph.with_players(tournament),
         labels <- Rounds.labels_for(matches),
         {:ok, rounds_multi} <-
           make_round_multi(matches, labels, tournament.id) |> Repo.transaction(),
         {:ok, matches_and_games_multi} <-
           make_game_match_multi(matches, rounds_multi) |> Repo.transaction(),
         {:ok, _} <- link_matches(matches, matches_and_games_multi) |> Repo.transaction() do
      {:ok, tournament.id}
    else
      {:error, error} -> {:error, error}
    end
  end

  @spec make_round_multi(list(MatchGraph.t()), %{number() => {String.t(), String.t()}}, number()) ::
          Ecto.Multi.t()
  def make_round_multi(match_graph, labels, tournament_id) do
    Enum.map(match_graph, & &1.round)
    |> Enum.uniq()
    |> Enum.reduce(Ecto.Multi.new(), fn round_number, acc ->
      {display_name, round_type} = Map.get(labels, round_number)

      acc
      |> Ecto.Multi.append(
        Ecto.Multi.new()
        |> Ecto.Multi.insert(
          round_number,
          %Round{}
          |> Round.changeset(%{
            number: round_number,
            type: round_type,
            display_name: display_name,
            status: :playing,
            tournament_id: tournament_id
          })
        )
      )
    end)
  end

  def make_game_match_multi(match_graph, rounds_multi) do
    Enum.reduce(match_graph, Ecto.Multi.new(), fn %MatchGraph{} = match, acc ->
      round_id = Map.get(rounds_multi, match.round).id
      match_changeset = BracketPairing.to_match_changeset(match.pairing, round_id)

      match_id = match.id
      match_multi = Ecto.Multi.new() |> Ecto.Multi.insert(match_id, match_changeset)

      match_multi =
        if has_game?(match) do
          Ecto.Multi.merge(match_multi, fn %{^match_id => db_match} ->
            Ecto.Multi.new()
            |> Ecto.Multi.insert(
              {:game, match.id},
              Ecto.build_assoc(
                db_match,
                :games,
                match.pairing
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

  def link_matches(match_graph, game_multi) do
    Enum.reduce(match_graph, Ecto.Multi.new(), fn %MatchGraph{} = match, acc ->
      db_match = Map.get(game_multi, match.id)

      links = %{
        winner_to_id: Map.get(game_multi, match.w, %{id: nil}).id,
        loser_to_id: Map.get(game_multi, match.l, %{id: nil}).id
      }

      acc
      |> Ecto.Multi.append(
        Ecto.Multi.new()
        |> Ecto.Multi.update({:match, db_match.id}, Match.changeset(db_match, links))
      )
    end)
  end

  def has_game?(%MatchGraph{
        pairing: %BracketPairing{
          player_one: player_one,
          player_two: player_two
        }
      }) do
    Enum.any?([player_one, player_two])
  end
end
