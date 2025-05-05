defmodule Elswisser.GamesTest do
  use Elswisser.DataCase

  alias Elswisser.Games

  describe "games" do
    import Elswisser.GamesFixtures
    import Elswisser.PlayersFixtures
    import Elswisser.RoundsFixtures
    import Elswisser.OpeningsFixture

    test "get_game!/1 returns the game with the given id" do
      game = game_fixture()
      assert Games.get_game!(game.id) == game
    end

    test "get_games_from_tournament_for_player/3 returns the correct games with preloaded players" do
      rnd = round_fixture()
      white = player_fixture()
      black = player_fixture()
      _game = game_fixture(rnd, white, black)

      games =
        Games.get_games_from_tournament_for_player(rnd.tournament_id, white.id, [white, black])

      assert length(games) == 1

      loaded = Enum.at(games, 0)
      assert loaded.white == white
      assert loaded.black == black
    end

    test "add_pgn/3 properly updates a pgn when the game is present" do
      game = game_fixture()
      {:ok, _} = Games.add_pgn(game.id, "TEST PGN", "http://chess.com/game/live/1234")
      game = Games.get_game!(game.id)
      assert game.game_link == "http://chess.com/game/live/1234"
      assert game.pgn == "TEST PGN"
    end

    test "add_pgn/2 properly returns an error when no game is found" do
      assert Games.add_pgn(-1, "TEST PGN", "link") == {:error, "Could not find game!"}
    end

    test "update_game/2 properly updates if there is a PGN attached but otherwise no opening" do
      opening = opening_fixture()
      game = game_fixture()

      {:ok, game} = Games.update_game(game, %{"pgn" => "1. e4 f6 2. d4 g5 3. Qh5# 1-0"})

      game = Games.get_game_with_players_and_opening!(game.id)
      assert game.opening == opening
    end
  end
end
