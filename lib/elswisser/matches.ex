defmodule Elswisser.Matches do
  require Elswisser.Pairings.Bye

  alias Elswisser.Games
  alias Elswisser.Games.Game
  alias Elswisser.Pairings.Bye
  alias Elswisser.Players
  alias Elswisser.Repo
  alias Elswisser.Matches.Match
  alias Elswisser.Rounds.Round
  alias Elswisser.Tournaments.Tournament

  def get_by_id(ids) when is_list(ids) do
    Match.from()
    |> Match.where_id(ids)
    |> Match.with_games()
    |> Match.preload_games()
    |> Repo.all()
  end

  def get_active_matches(tournament_id, type \\ :full) do
    query =
      Match.from()
      |> Match.where_tournament_id(tournament_id)
      |> Match.with_games()
      |> Match.with_round()
      |> Round.where_status(:playing)
      |> Game.where_both_players()
      |> Game.where_unfinished()
      |> Game.with_both_players()

    query =
      case type do
        :mini -> Match.Mini.select_into(query)
        :full -> Match.preload_games_and_players(query) |> Match.preload_round()
      end

    Repo.all(query)
  end

  def create_match(attrs \\ %{}) do
    %Match{}
    |> Match.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Given game attributes, create a match and a surrounding game for that match
  """
  def create_match_from_game(attrs, board) do
    {match_attrs, game_attrs} = parse_match_and_game(attrs, board)

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:match, %Match{} |> Match.changeset(match_attrs))
    |> Ecto.Multi.merge(fn %{match: match} ->
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:game, Ecto.build_assoc(match, :games, game_attrs))
    end)
    |> Repo.transaction()
  end

  @doc """
  Given an array of game attributes, create matches with a single game inside
  each match.
  """
  def create_matches_from_games(games \\ []) do
    games
    |> Enum.with_index(1)
    |> Enum.reduce(Ecto.Multi.new(), fn {game, idx}, acc ->
      {match_attrs, game_attrs} = parse_match_and_game(game, idx)

      changeset = %Match{} |> Match.changeset(match_attrs)

      multi_id = String.to_atom("match-#{idx}")

      acc
      |> Ecto.Multi.append(
        Ecto.Multi.new()
        |> Ecto.Multi.insert(multi_id, changeset)
        |> Ecto.Multi.merge(fn %{^multi_id => match} ->
          Ecto.Multi.new()
          |> Ecto.Multi.insert({:game, idx}, Ecto.build_assoc(match, :games, game_attrs))
        end)
      )
    end)
    |> Repo.transaction()
  end

  def delete_from_game(%Game{} = game) do
    Repo.delete(%Match{id: game.match_id})
  end

  defp parse_match_and_game(attrs, board) do
    {display_order, game} = Map.pop(attrs, :display_order)
    display_order = if is_nil(display_order), do: board, else: display_order

    match_attrs = %{
      display_order: display_order,
      board: board,
      round_id: game.round_id,
      # Copy player/seed info from game to match
      player_one_id: Map.get(attrs, :white_id),
      player_two_id: Map.get(attrs, :black_id),
      player_one_seed: Map.get(attrs, :white_seed),
      player_two_seed: Map.get(attrs, :black_seed)
    }

    {match_attrs, attrs}
  end

  @doc """
  Creates the next game within an existing match, alternating colors from the previous game.

  The match must have games, player_one, and player_two preloaded.

  Before creating the next game, this function updates player ratings based on
  the most recently completed game if ratings haven't been updated yet.

  Returns an error if:
  - The match is already complete according to tournament rules
  - The match has no existing games
  - Either player is a bye player
  - The last game in the match is not complete
  """
  @spec create_next_game(Match.t(), Tournament.t()) ::
          {:ok, Game.t()}
          | {:error, :match_complete | :no_games | :bye_match | :last_game_incomplete}
  def create_next_game(%Match{games: []}, _tournament), do: {:error, :no_games}

  def create_next_game(%Match{} = match, %Tournament{} = tournament) do
    last_game = get_last_game(match)

    with :ok <- validate_not_bye(match),
         :ok <- validate_not_complete(match, tournament),
         :ok <- validate_last_game_complete(last_game),
         {:ok, _} <- maybe_update_ratings(last_game),
         {white_id, black_id} <- Match.next_game_colors(match),
         white <- Players.get_player!(white_id),
         black <- Players.get_player!(black_id) do
      Games.create_game(%{
        match_id: match.id,
        round_id: match.round_id,
        tournament_id: tournament.id,
        white_id: white.id,
        white_rating: white.rating,
        black_id: black.id,
        black_rating: black.rating
      })
    else
      nil -> {:error, :no_games}
      error -> error
    end
  end

  defp get_last_game(%Match{games: games}) do
    games |> Enum.sort_by(& &1.inserted_at, :asc) |> List.last()
  end

  defp validate_last_game_complete(%Game{result: nil}), do: {:error, :last_game_incomplete}
  defp validate_last_game_complete(%Game{}), do: :ok

  # Database default is 0, so we need to check for both nil and 0 as "not yet updated"
  defp maybe_update_ratings(%Game{white_rating_change: change})
       when not is_nil(change) and change != 0 do
    {:ok, :already_updated}
  end

  defp maybe_update_ratings(%Game{} = game) do
    game |> Games.update_player_ratings()
  end

  defp validate_not_bye(%Match{} = match) do
    if Bye.bye_player?(match.player_one) or Bye.bye_player?(match.player_two) do
      {:error, :bye_match}
    else
      :ok
    end
  end

  defp validate_not_complete(%Match{} = match, %Tournament{} = tournament) do
    if Match.complete?(match, tournament) do
      {:error, :match_complete}
    else
      :ok
    end
  end
end
