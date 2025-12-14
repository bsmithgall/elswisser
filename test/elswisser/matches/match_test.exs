defmodule Elswisser.Matches.MatchTest do
  use ExUnit.Case, async: true

  alias Elswisser.Games.Game
  alias Elswisser.Matches.Match
  alias Elswisser.Players.Player
  alias Elswisser.Tournaments.Tournament

  describe "result/1 with multiple games" do
    test "returns nil for match with no games" do
      match = %Match{games: []}
      assert {nil, nil} == Match.result(match)
    end

    test "returns player_one as winner when they win more games" do
      match = match_with_games([1, -1, 1])
      assert {{p1(), p1_seed()}, {p2(), p2_seed()}} == Match.result(match)
    end

    test "returns player_two as winner when they win more games" do
      match = match_with_games([-1, 1, -1])
      assert {{p2(), p2_seed()}, {p1(), p1_seed()}} == Match.result(match)
    end

    test "returns nil when tied with draws" do
      match = match_with_games([0, 0])
      assert {nil, nil} == Match.result(match)
    end

    test "returns nil when multiple games sum to a tie" do
      match = match_with_games([1, 1, -1, -1])
      assert {nil, nil} == Match.result(match)
    end

    test "works for comeback victory for white" do
      match = match_with_games([-1, 1, 1])
      assert {{p1(), p1_seed()}, {p2(), p2_seed()}} == Match.result(match)
    end

    test "works for comeback victory for black" do
      match = match_with_games([1, -1, -1])
      assert {{p2(), p2_seed()}, {p1(), p1_seed()}} == Match.result(match)
    end

    test "returns nil with incomplete games" do
      match = match_with_games([1, 1, nil])
      assert {nil, nil} == Match.result(match)
    end

    defp p1, do: %Player{id: 1}
    defp p1_seed, do: 1
    defp p2, do: %Player{id: 2}
    defp p2_seed, do: 2

    defp match_with_games(results) do
      games =
        results
        |> Enum.with_index()
        |> Enum.map(fn {result, idx} ->
          if rem(idx, 2) == 0 do
            p1_white(result)
          else
            p1_black(result)
          end
        end)

      %Match{games: games}
    end

    defp p1_white(result),
      do: %Game{
        white: p1(),
        white_seed: p1_seed(),
        black: p2(),
        black_seed: p2_seed(),
        result: result
      }

    defp p1_black(result),
      do: %Game{
        black: p1(),
        black_seed: p1_seed(),
        white: p2(),
        white_seed: p2_seed(),
        result: result
      }
  end

  describe "complete?/2" do
    test "returns false for empty match" do
      match = %Match{games: []}
      tournament = tournament(:first_to, 3)
      refute Match.complete?(match, tournament)
    end

    test "returns false when any game is incomplete" do
      match = match_with_games([1, 1, nil])
      tournament = tournament(:first_to, 3)
      refute Match.complete?(match, tournament)
    end

    test "first_to format: returns true when a player reaches points_to_win" do
      # P1 wins 3 games (reaches 3 points)
      match = match_with_games([1, -1, 1, -1, 1])
      tournament = tournament(:first_to, 3)
      assert Match.complete?(match, tournament)
    end

    test "first_to format: returns false when neither player has reached points_to_win" do
      # P1: 1 win + 1 draw = 1.5 points, P2: 1 draw = 0.5 points (need 3 to win)
      match = match_with_games([1, 0])
      tournament = tournament(:first_to, 3)
      refute Match.complete?(match, tournament)
    end

    test "first_to format: counts draws as 0.5 points each" do
      # P1: 2 wins + 2 draws = 3 points (reaches 3)
      match = match_with_games([1, 0, 1, 0])
      tournament = tournament(:first_to, 3)
      assert Match.complete?(match, tournament)
    end

    test "best_of format: returns true when enough games played" do
      # Best of 5: need 3 games to win (5 games total)
      match = match_with_games([1, -1, 1, -1, 1])
      tournament = tournament(:best_of, 5)
      assert Match.complete?(match, tournament)
    end

    test "best_of format: returns true when majority is reached early" do
      # Best of 5: P1 wins 3 out of first 3 games (3 points, can't lose anymore)
      # With 2 games remaining, P2 can only reach 2 points max, so P1 has clinched
      match = match_with_games([1, -1, 1])
      tournament = tournament(:best_of, 5)
      assert Match.complete?(match, tournament)
    end

    test "best_of format: returns false when not enough games played and no majority" do
      # Best of 5: only 2 games played, P1 has 2 points (not majority of 3 yet)
      match = match_with_games([1, 1])
      tournament = tournament(:best_of, 5)
      refute Match.complete?(match, tournament)
    end

    test "best_of format: returns true when player clinches with draws" do
      # Best of 5: P1 has 3 points (2 wins + 2 draws), P2 has 1 point (2 draws)
      # With 1 game remaining, P2 can only reach 2 max, so P1 has clinched
      match = match_with_games([1, 0, 1, 0])
      tournament = tournament(:best_of, 5)
      assert Match.complete?(match, tournament)
    end

    test "best_of format: returns false when tie is still possible with draws" do
      # Best of 4: P1 has 1.5 (1 win + 1 draw), P2 has 0.5 (1 draw)
      # With 2 games left, either player could still win or tie
      match = match_with_games([1, 0])
      tournament = tournament(:best_of, 4)
      refute Match.complete?(match, tournament)
    end

    test "first_to format: returns false when tied and draws not allowed" do
      # P1: 1 point (2 draws), P2: 1 point (2 draws) - tied at 1-1 in first_to 1
      # With allow_draws: false, this should not be complete even though tied at threshold
      match = match_with_games([0, 0])
      tournament = tournament(:first_to, 1, false)
      refute Match.complete?(match, tournament)
    end

    test "first_to format: returns true when tied and draws are allowed" do
      # P1: 1 point (2 draws), P2: 1 point (2 draws) - tied at 1-1 in first_to 1
      # With allow_draws: true, this should be complete (tie is acceptable)
      match = match_with_games([0, 0])
      tournament = tournament(:first_to, 1, true)
      assert Match.complete?(match, tournament)
    end

    test "best_of format: returns false when tied and draws not allowed" do
      # Best of 4: P1: 2 points (4 draws), P2: 2 points (4 draws) - tied 2-2
      # With allow_draws: false, this should not be complete even though all games played
      match = match_with_games([0, 0, 0, 0])
      tournament = tournament(:best_of, 4, false)
      refute Match.complete?(match, tournament)
    end

    test "best_of format: returns true when tied and draws are allowed" do
      # Best of 4: P1: 2 points (4 draws), P2: 2 points (4 draws) - tied 2-2
      # With allow_draws: true, this should be complete (tie is acceptable)
      match = match_with_games([0, 0, 0, 0])
      tournament = tournament(:best_of, 4, true)
      assert Match.complete?(match, tournament)
    end

    defp tournament(format, points, allow_draws \\ true) do
      %Tournament{match_format: format, points_to_win: points, allow_draws: allow_draws}
    end
  end
end
