defmodule Elswisser.MatchesTest do
  use Elswisser.DataCase

  alias Elswisser.Matches
  alias Elswisser.Repo

  describe "create_next_game/2" do
    import Elswisser.MatchFixture
    import Elswisser.PlayersFixtures
    import Elswisser.TournamentsFixtures

    test "creates game with alternating colors" do
      {tournament, round} = tournament_and_round_fixture(:best_of, 5)
      # Create match with one completed game
      match = match_with_games_fixture(round, tournament, [1])
      match = Repo.preload(match, [:games, :player_one, :player_two])

      first_game = hd(match.games)

      {:ok, next_game} = Matches.create_next_game(match, tournament)

      # Colors should be swapped
      assert next_game.white_id == first_game.black_id
      assert next_game.black_id == first_game.white_id
      assert next_game.match_id == match.id
      assert next_game.round_id == match.round_id
      assert next_game.tournament_id == tournament.id
    end

    test "updates ratings from previous game before creating next game" do
      {tournament, round} = tournament_and_round_fixture(:best_of, 5)
      player1 = player_fixture(%{name: "Alice", rating: 1200})
      player2 = player_fixture(%{name: "Bob", rating: 1800})

      {:ok, match} =
        Matches.create_match(%{
          board: 1,
          display_order: 1,
          round_id: round.id,
          player_one_id: player1.id,
          player_two_id: player2.id,
          player_one_seed: 1,
          player_two_seed: 2
        })

      # Create first game with a result (white wins)
      {:ok, first_game} =
        Elswisser.Games.create_game(%{
          match_id: match.id,
          round_id: round.id,
          tournament_id: tournament.id,
          white_id: player1.id,
          black_id: player2.id,
          white_rating: player1.rating,
          black_rating: player2.rating,
          result: 1
        })

      # Verify ratings haven't been updated yet (database default is 0)
      assert first_game.white_rating_change == 0

      match = Repo.preload(match, [:games, :player_one, :player_two])
      {:ok, next_game} = Matches.create_next_game(match, tournament)

      # Verify first game now has non-zero rating changes recorded
      updated_first_game = Elswisser.Games.get_game!(first_game.id)
      refute updated_first_game.white_rating_change == 0
      refute updated_first_game.black_rating_change == 0

      # Player ratings should be updated
      updated_player1 = Elswisser.Players.get_player!(player1.id)
      updated_player2 = Elswisser.Players.get_player!(player2.id)

      # Winner's rating should increase, loser's should decrease
      assert updated_player1.rating > player1.rating
      assert updated_player2.rating < player2.rating

      # Next game should use the updated ratings
      assert next_game.white_rating == updated_player2.rating
      assert next_game.black_rating == updated_player1.rating
    end

    test "skips rating update if already updated" do
      {tournament, round} = tournament_and_round_fixture(:best_of, 5)
      player1 = player_fixture(%{name: "Alice", rating: 1500})
      player2 = player_fixture(%{name: "Bob", rating: 1500})

      {:ok, match} =
        Matches.create_match(%{
          board: 1,
          display_order: 1,
          round_id: round.id,
          player_one_id: player1.id,
          player_two_id: player2.id,
          player_one_seed: 1,
          player_two_seed: 2
        })

      # Create first game with result and rating changes already set
      {:ok, _first_game} =
        Elswisser.Games.create_game(%{
          match_id: match.id,
          round_id: round.id,
          tournament_id: tournament.id,
          white_id: player1.id,
          black_id: player2.id,
          white_rating: 1500,
          black_rating: 1500,
          white_rating_change: 10,
          black_rating_change: -10,
          result: 1
        })

      match = Repo.preload(match, [:games, :player_one, :player_two])
      {:ok, _next_game} = Matches.create_next_game(match, tournament)

      # Player ratings should NOT have changed (ratings were already applied)
      unchanged_player1 = Elswisser.Players.get_player!(player1.id)
      unchanged_player2 = Elswisser.Players.get_player!(player2.id)
      assert unchanged_player1.rating == 1500
      assert unchanged_player2.rating == 1500
    end

    test "returns error when match is complete" do
      {tournament, round} = tournament_and_round_fixture(:best_of, 3)
      # 2 wins for player1 in best of 3 = clinched victory
      match = match_with_games_fixture(round, tournament, [1, -1, 1])
      match = Repo.preload(match, [:games, :player_one, :player_two])

      assert {:error, :match_complete} = Matches.create_next_game(match, tournament)
    end

    test "returns error when match has no games" do
      {tournament, round} = tournament_and_round_fixture(:best_of, 5)

      {:ok, match} =
        Matches.create_match(%{
          board: 1,
          display_order: 1,
          round_id: round.id
        })

      match = Repo.preload(match, [:games, :player_one, :player_two])

      assert {:error, :no_games} = Matches.create_next_game(match, tournament)
    end

    test "returns error when last game is incomplete" do
      {tournament, round} = tournament_and_round_fixture(:best_of, 5)
      match = match_with_games_fixture(round, tournament, [nil])
      match = Repo.preload(match, [:games, :player_one, :player_two])

      assert {:error, :last_game_incomplete} = Matches.create_next_game(match, tournament)
    end

    test "returns error when either player is a bye" do
      {tournament, round} = tournament_and_round_fixture(:best_of, 5)
      bye_player = Repo.get!(Elswisser.Players.Player, -1)
      regular_player = player_fixture(%{name: "Alice"})

      {:ok, match} =
        Matches.create_match(%{
          board: 1,
          display_order: 1,
          round_id: round.id,
          player_one_id: bye_player.id,
          player_two_id: regular_player.id,
          player_one_seed: 1,
          player_two_seed: 2
        })

      {:ok, _game} =
        Elswisser.Games.create_game(%{
          match_id: match.id,
          round_id: round.id,
          tournament_id: tournament.id,
          white_id: bye_player.id,
          black_id: regular_player.id,
          result: 0
        })

      match = Repo.preload(match, [:games, :player_one, :player_two])

      assert {:error, :bye_match} = Matches.create_next_game(match, tournament)
    end

    test "correctly alternates colors across multiple game additions" do
      {tournament, round} = tournament_and_round_fixture(:best_of, 5)
      match = match_with_games_fixture(round, tournament, [1])
      match = Repo.preload(match, [:games, :player_one, :player_two])

      first_game = hd(match.games)
      first_white = first_game.white_id

      # Add second game
      {:ok, second_game} = Matches.create_next_game(match, tournament)
      assert second_game.white_id != first_white

      # Complete the second game
      {:ok, _} = Elswisser.Games.update_game(second_game, %{result: -1})

      # Reload match with new games
      match = Repo.preload(match, [:games], force: true)

      # Add third game
      {:ok, third_game} = Matches.create_next_game(match, tournament)
      assert third_game.white_id == first_white
    end
  end
end
