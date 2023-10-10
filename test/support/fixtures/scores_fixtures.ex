defmodule Elswisser.ScoresFixtures do
  alias Elswisser.Games.Game
  alias Elswisser.Rounds.Round

  alias Elswisser.PlayersFixtures

  @doc """
  set up a tournament with 8 players and 3 rounds. game results
  chosen in no specific way player IDs are just their relative position in
  alphabetical order
  """
  def scores_fixture() do
    Elswisser.Scores.calculate([
      %{
        game: %Game{
          white_id: 4,
          black_id: 1,
          result: -1
        },
        rnd: %Round{number: 1}
      },
      %{
        game: %Game{
          white_id: 3,
          black_id: 2,
          result: -1
        },
        rnd: %Round{number: 1}
      },
      %{
        game: %Game{
          white_id: 8,
          black_id: 6,
          result: 1
        },
        rnd: %Round{number: 1}
      },
      %{
        game: %Game{
          white_id: 7,
          black_id: 5,
          result: 1
        },
        rnd: %Round{number: 1}
      },
      %{
        game: %Game{
          white_id: 2,
          black_id: 1,
          result: 1
        },
        rnd: %Round{number: 2}
      },
      %{
        game: %Game{
          white_id: 8,
          black_id: 7,
          result: -1
        },
        rnd: %Round{number: 2}
      },
      %{
        game: %Game{
          white_id: 6,
          black_id: 3,
          result: -1
        },
        rnd: %Round{number: 2}
      },
      %{
        game: %Game{
          white_id: 5,
          black_id: 4,
          result: -1
        },
        rnd: %Round{number: 2}
      },
      %{
        game: %Game{
          white_id: 7,
          black_id: 2,
          result: 1
        },
        rnd: %Round{number: 3}
      },
      %{
        game: %Game{
          white_id: 4,
          black_id: 3,
          result: 1
        },
        rnd: %Round{number: 3}
      },
      %{
        game: %Game{
          white_id: 1,
          black_id: 8,
          result: -1
        },
        rnd: %Round{number: 3}
      },
      %{
        game: %Game{
          white_id: 6,
          black_id: 5,
          result: -1
        },
        rnd: %Round{number: 3}
      }
    ])
  end

  @doc """
  Given the baseline tournament from above, merge it with players. Player
  ratings are their id * 100.
  """
  def scores_fixture_with_players() do
    scores_fixture()
    |> Elswisser.Scores.with_players(players())
  end

  def scores_fixture_with_players_first_round() do
    Elswisser.Scores.calculate([])
    |> Elswisser.Scores.with_players(players())
  end

  defp players() do
    [
      PlayersFixtures.player_fixture(%{id: 1, rating: 100}),
      PlayersFixtures.player_fixture(%{id: 2, rating: 200}),
      PlayersFixtures.player_fixture(%{id: 3, rating: 300}),
      PlayersFixtures.player_fixture(%{id: 4, rating: 400}),
      PlayersFixtures.player_fixture(%{id: 5, rating: 500}),
      PlayersFixtures.player_fixture(%{id: 6, rating: 600}),
      PlayersFixtures.player_fixture(%{id: 7, rating: 700}),
      PlayersFixtures.player_fixture(%{id: 8, rating: 800})
    ]
  end
end
