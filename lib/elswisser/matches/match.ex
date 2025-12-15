defmodule Elswisser.Matches.Match do
  require Elswisser.Pairings.Bye
  alias Elswisser.Tournaments.Tournament
  alias Elswisser.Pairings.Bye
  alias Elswisser.Players.Player
  alias Elswisser.Games.Game
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query, warn: false

  @type t :: %__MODULE__{}
  alias __MODULE__

  schema "matches" do
    field :board, :integer
    field :display_order, :integer
    field :player_one_seed, :integer
    field :player_two_seed, :integer

    belongs_to(:player_one, Player)
    belongs_to(:player_two, Player)

    belongs_to(:winner_to, Match)
    belongs_to(:loser_to, Match)

    belongs_to(:winner, Player)

    belongs_to(:round, Elswisser.Rounds.Round)
    has_many(:games, Elswisser.Games.Game)

    timestamps()
  end

  @doc false
  def changeset(match, attrs \\ %{}) do
    match
    |> cast(attrs, [
      :board,
      :display_order,
      :round_id,
      :loser_to_id,
      :winner_to_id,
      :player_one_id,
      :player_two_id,
      :player_one_seed,
      :player_two_seed
    ])
    |> validate_required([:board, :display_order, :round_id])
  end

  def from() do
    from(m in Match, as: :match)
  end

  def where_id(query, ids) when is_list(ids) do
    from([match: m] in query, where: m.id in ^ids)
  end

  def where_tournament_id(query, tournament_id) do
    from([match: m] in query,
      join: r in assoc(m, :round),
      join: t in assoc(r, :tournament),
      where: t.id == ^tournament_id
    )
  end

  def with_round(query) do
    from([match: m] in query, join: r in assoc(m, :round), as: :round)
  end

  def with_games(query), do: with_games(query, false)

  def with_games(query, false) do
    from([match: m] in query, left_join: g in assoc(m, :games), as: :game)
  end

  def preload_games(query) do
    from([game: g] in query, preload: [games: g])
  end

  def preload_games_and_players(query) do
    from([game: g, white: w, black: b] in query, preload: [games: {g, black: b, white: w}])
  end

  def preload_round(query) do
    from([round: r] in query, preload: [round: r])
  end

  def order_by_display_number(query) do
    from([match: m] in query, order_by: [asc: m.display_order])
  end

  def where_round_id(query, round_id) do
    from([match: m] in query, where: m.round_id == ^round_id)
  end

  def with_players(query) do
    query |> with_player_one() |> with_player_two()
  end

  def with_player_one(query) do
    from([match: m] in query, left_join: p1 in assoc(m, :player_one), as: :player_one)
  end

  def with_player_two(query) do
    from([match: m] in query, left_join: p2 in assoc(m, :player_two), as: :player_two)
  end

  def preload_players(query) do
    from([player_one: p1, player_two: p2] in query, preload: [player_one: p1, player_two: p2])
  end

  @doc """
  Returns changeset attrs to seat a player in an available slot on the match.

  Similar to Game.take_seat, but for match-level player assignments.
  """
  def take_seat(%Match{player_one_id: nil, player_two_id: nil}, %Player{} = player, seed) do
    # Both slots empty - randomly assign to player_one or player_two
    case Enum.random(0..1) do
      0 -> %{player_one_id: player.id, player_one_seed: seed}
      1 -> %{player_two_id: player.id, player_two_seed: seed}
    end
  end

  def take_seat(%Match{player_one_id: nil, player_two_id: _}, %Player{} = player, seed) do
    %{player_one_id: player.id, player_one_seed: seed}
  end

  def take_seat(%Match{player_one_id: _, player_two_id: nil}, %Player{} = player, seed) do
    %{player_two_id: player.id, player_two_seed: seed}
  end

  def take_seat(
        %Player{} = player_one,
        player_one_seed,
        %Player{} = player_two,
        player_two_seed
      ) do
    %{
      player_one_id: player_one.id,
      player_one_seed: player_one_seed,
      player_two_id: player_two.id,
      player_two_seed: player_two_seed
    }
  end

  def first_game_or_nil(nil), do: nil

  def first_game_or_nil(%Match{} = match) do
    Enum.at(match.games, 0)
  end

  @doc """
  Calculates the result of a match across all games.

  Returns a tuple of `{{winner, winner_seed}, {loser, loser_seed}}` if the match
  has a decisive result. Returns `{nil, nil}` if:
  - The match has no games
  - Any game has a nil result (match incomplete), OR
  - The aggregated score is tied and neither player is a bye

  For matches involving bye players, the non-bye player is always the winner,
  even if the score is 0.

  ## Assumptions
  - Players alternate colors between games within a match (required invariant)
  - Game results are scored as: white win = 1, draw = 0, black win = -1
  - The match aggregates results by summing individual game scores
  """
  @spec result(t()) :: {{Player.t(), integer()}, {Player.t(), integer()}} | {nil, nil}
  def result(%Match{games: []}), do: {nil, nil}

  def result(%Match{games: games} = match) do
    results = Enum.map(games, & &1.result)

    # Return nil if any game is incomplete
    if nil in results do
      {nil, nil}
    else
      {p1_score, p2_score} = calculate_player_scores(match)
      calculate_result(match, p1_score, p2_score)
    end
  end

  defp calculate_result(%Match{} = match, p1_score, p2_score) when p1_score > p2_score do
    {{match.player_one, match.player_one_seed}, {match.player_two, match.player_two_seed}}
  end

  defp calculate_result(%Match{} = match, p1_score, p2_score) when p1_score < p2_score do
    {{match.player_two, match.player_two_seed}, {match.player_one, match.player_one_seed}}
  end

  defp calculate_result(%Match{} = match, _, _) do
    cond do
      Bye.bye_player?(match.player_one) ->
        {{match.player_two, match.player_two_seed}, {match.player_one, match.player_one_seed}}

      Bye.bye_player?(match.player_two) ->
        {{match.player_one, match.player_one_seed}, {match.player_two, match.player_two_seed}}

      true ->
        {nil, nil}
    end
  end

  def winner(%Match{} = match), do: result(match) |> elem(0)
  def loser(%Match{} = match), do: result(match) |> elem(1)

  @doc """
  Determines if a match is complete based on tournament configuration.

  Returns `true` if the match is finished according to the tournament's match format:

  - `:first_to` format: A player has reached `points_to_win` points
  - `:best_of` format: All games have been played OR a player has clinched victory
    (accumulated enough points that the opponent cannot possibly catch up)

  Returns `false` if:
  - The match has no games
  - Any game is incomplete (nil result)
  - Neither completion condition is met
  - The match is tied and `allow_draws` is false

  Points are calculated as: win = 1 point, draw = 0.5 points, loss = 0 points
  """
  @spec complete?(t(), Tournament.t()) :: boolean()
  def complete?(%Match{games: []}, _), do: false

  def complete?(%Match{games: games} = match, tournament) do
    results = Enum.map(games, & &1.result)

    case nil in results do
      true -> false
      false -> check_completion(match, tournament)
    end
  end

  defp check_completion(%Match{} = match, %Tournament{
         match_format: :first_to,
         points_to_win: points_to_win,
         allow_draws: allow_draws
       }) do
    {p1_score, p2_score} = calculate_player_scores(match)

    (p1_score >= points_to_win or p2_score >= points_to_win) and
      (allow_draws or p1_score != p2_score)
  end

  defp check_completion(%Match{games: games} = match, %Tournament{
         match_format: :best_of,
         points_to_win: total_games,
         allow_draws: allow_draws
       }) do
    games_played = length(games)
    {p1_score, p2_score} = calculate_player_scores(match)

    # Match is complete if all games played OR a player has clinched victory
    case games_played >= total_games do
      true ->
        allow_draws or p1_score != p2_score

      _ ->
        # A player clinches when their current score exceeds what their opponent
        # could possibly achieve. Maximum possible score = current + all remaining
        # games (1 point each). This works even with draws since each game awards
        # at most 1 point total between both players.
        remaining_games = total_games - games_played

        p2_max_possible = p2_score + remaining_games
        p1_max_possible = p1_score + remaining_games

        p1_score > p2_max_possible or p2_score > p1_max_possible
    end
  end

  defp calculate_player_scores(%Match{games: games, player_one_id: player_one_id}) do
    Enum.reduce(games, {0, 0}, fn game, {p1_score, p2_score} ->
      white_pts = Game.white_score(game)
      black_pts = Game.black_score(game)

      cond do
        game.white_id == player_one_id ->
          {p1_score + white_pts, p2_score + black_pts}

        game.black_id == player_one_id ->
          {p1_score + black_pts, p2_score + white_pts}

        true ->
          {p1_score, p2_score}
      end
    end)
  end

  defmodule Mini do
    @moduledoc """
    Mini projection of fields needed for displaying match pairings and generating alerts
    """
    use Ecto.Schema
    import Ecto.Query, warn: false

    alias Elswisser.Players.Player

    @primary_key false
    embedded_schema do
      field :id, :integer
      field :round_id, :integer
      field :round_display_name, :string
      embeds_one :white, Players.Mini
      embeds_one :black, Players.Mini
    end

    def select_into(query) do
      from([match: m, round: r, game: g, white: w, black: b] in query,
        select: %Mini{
          id: m.id,
          round_id: r.id,
          round_display_name: r.display_name,
          white: %Player.Mini{
            name: w.name,
            rating: w.rating,
            chesscom: w.chesscom,
            lichess: w.lichess,
            slack_id: w.slack_id
          },
          black: %Player.Mini{
            name: b.name,
            rating: b.rating,
            chesscom: b.chesscom,
            lichess: b.lichess,
            slack_id: b.slack_id
          }
        }
      )
    end
  end
end
