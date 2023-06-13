defmodule Elswisser.GamesTest do
  use Elswisser.DataCase

  alias Elswisser.Games

  describe "games" do
    import Elswisser.GamesFixtures
    import Elswisser.PlayersFixtures
    import Elswisser.RoundsFixtures

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
  end
end
