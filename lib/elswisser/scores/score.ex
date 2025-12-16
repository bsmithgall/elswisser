defmodule Elswisser.Scores.Score do
  use Ecto.Schema
  alias Elswisser.Players.Player
  alias Elswisser.Scores.Score
  alias Elswisser.Pairings.Bye
  alias Elswisser.Games.Game
  alias Elswisser.Rounds.Round

  embedded_schema do
    field :player_id, :integer
    field :opponents, {:array, :integer}, default: []
    field :results, {:array, :integer}, default: []
    field :score, :integer, default: 0
    field :modmed, :integer, default: 0
    field :solkoff, :integer, default: 0
    field :cumulative_sum, :integer, default: 0
    field :cumulative_opp, :integer, default: 0
    field :nblack, :integer, default: 0
    field :lastwhite, :boolean
    field :rating_change, :integer, default: 0
    embeds_one :player, Player
  end

  def had_bye?(%Score{} = score) do
    Enum.any?(score.opponents, fn o -> o == Bye.bye_player_id() end)
  end

  def white(%Game{} = game, %Round{} = rnd) do
    %Score{
      player_id: game.white_id,
      player: game.white,
      score: Game.white_score(game),
      rating_change: game.white_rating_change |> or_zero(),
      opponents: [game.black_id],
      results: [Game.white_result(game)],
      cumulative_sum: Game.white_score(game) * rnd.number,
      lastwhite: true
    }
  end

  def black(%Game{} = game, %Round{} = rnd) do
    %Score{
      player_id: game.black_id,
      score: Game.black_score(game),
      rating_change: game.black_rating_change |> or_zero(),
      opponents: [game.white_id],
      results: [Game.black_result(game)],
      cumulative_sum: Game.black_score(game) * rnd.number,
      nblack: 1,
      lastwhite: false
    }
  end

  def merge_white(%Score{} = ex, %Game{} = game, %Round{} = rnd) do
    Map.merge(ex, %{
      score: ex.score + Game.white_score(game),
      rating_change: ex.rating_change + (game.white_rating_change |> or_zero()),
      opponents: ex.opponents ++ [game.black_id],
      results: ex.results ++ [Game.white_result(game)],
      cumulative_sum: ex.cumulative_sum + Game.white_score(game) * rnd.number,
      lastwhite: true
    })
  end

  def merge_black(%Score{} = ex, %Game{} = game, %Round{} = rnd) do
    Map.merge(ex, %{
      score: ex.score + Game.black_score(game),
      rating_change: ex.rating_change + (game.black_rating_change |> or_zero()),
      opponents: ex.opponents ++ [game.white_id],
      results: ex.results ++ [Game.black_result(game)],
      cumulative_sum: ex.cumulative_sum + Game.black_score(game) * rnd.number,
      nblack: ex.nblack + 1,
      lastwhite: false
    })
  end

  def or_zero(nil), do: 0
  def or_zero(n) when is_integer(n), do: n
end
