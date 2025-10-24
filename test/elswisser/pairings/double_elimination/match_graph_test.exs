defmodule Elswisser.Pairings.DoubleElimination.MatchGraphTest do
  use ExUnit.Case, async: true

  alias Elswisser.Pairings.DoubleElimination.MatchGraph

  describe "winners half" do
    for {name, params} <- %{
          "4 players" => %{size: 4, matches: [2, 1]},
          "8 players" => %{size: 8, matches: [4, 2, 1]},
          "12 players" => %{size: 12, matches: [8, 4, 2, 1]},
          "16 players" => %{size: 16, matches: [8, 4, 2, 1]}
        } do
      @tag params: params
      test name, %{params: params} do
        actual = MatchGraph.winners_half(params.size) |> MatchGraph.link_winners()

        assert length(actual) == length(params.matches)

        Enum.zip(actual, params.matches)
        |> Enum.map(fn {matches, expected_size} ->
          assert length(matches) == expected_size
        end)
      end
    end
  end

  describe "losers_half" do
    for {name, params} <- %{
          "8 players" => %{size: 8, matches: [2, 2, 1, 1]},
          "12 players" => %{size: 12, matches: [4, 4, 2, 2, 1, 1]},
          "16 players" => %{size: 16, matches: [4, 4, 2, 2, 1, 1]}
        } do
      @tag params: params
      test name, %{params: params} do
        actual = MatchGraph.losers_half(params.size) |> MatchGraph.link_losers(0)

        assert length(actual) == length(params.matches)

        Enum.zip(actual, params.matches)
        |> Enum.map(fn {matches, expected_size} ->
          assert length(matches) == expected_size
        end)
      end
    end
  end

  describe "next_pow2/1" do
    for {name, params} <- %{
          "eight" => %{num: 8, res: 8},
          "fifteen" => %{num: 15, res: 16},
          "sixteen" => %{num: 16, res: 16},
          "twenty-four" => %{num: 24, res: 32}
        } do
      @tag params: params
      test name, %{params: params} do
        assert MatchGraph.next_pow2(params.num) == params.res
      end
    end
  end

  describe "next_pattern/2" do
    for {name, params} <- %{
          "normal case" => %{num: 4, p: 1, res: [0, 1, 2, 3]},
          "reverse case" => %{num: 4, p: 2, res: [3, 2, 1, 0]},
          "rotate case" => %{num: 4, p: 3, res: [2, 3, 0, 1]},
          "reverse rotate case" => %{num: 4, p: 4, res: [1, 0, 3, 2]},
          "back around to normal case" => %{num: 4, p: 5, res: [0, 1, 2, 3]}
        } do
      @tag params: params
      test name, %{params: params} do
        assert MatchGraph.next_pattern(params.num, params.p) == params.res
      end
    end
  end

  describe "generate/1" do
    for {name, params} <- %{
          "4 players" => %{
            size: 4,
            res: [
              %MatchGraph{id: 0, type: :w, round: 1, w: 2, l: 3},
              %MatchGraph{id: 1, type: :w, round: 1, w: 2, l: 3},
              %MatchGraph{id: 2, type: :w, round: 2, w: 5, l: 4},
              %MatchGraph{id: 3, type: :lm, round: 3, w: 4, l: nil},
              %MatchGraph{id: 4, type: :lm, round: 4, w: 5, l: nil},
              %MatchGraph{id: 5, type: :c, round: 5, w: 6, l: 6},
              %MatchGraph{id: 6, type: :c, round: 6, w: nil, l: nil}
            ]
          },
          "8 players" => %{
            size: 8,
            res: [
              %MatchGraph{id: 0, type: :w, round: 1, w: 4, l: 7},
              %MatchGraph{id: 1, type: :w, round: 1, w: 4, l: 7},
              %MatchGraph{id: 2, type: :w, round: 1, w: 5, l: 8},
              %MatchGraph{id: 3, type: :w, round: 1, w: 5, l: 8},
              %MatchGraph{id: 4, type: :w, round: 2, w: 6, l: 10},
              %MatchGraph{id: 5, type: :w, round: 2, w: 6, l: 9},
              %MatchGraph{id: 6, type: :w, round: 3, w: 13, l: 12},
              %MatchGraph{id: 7, type: :lm, round: 4, w: 9, l: nil},
              %MatchGraph{id: 8, type: :lm, round: 4, w: 10, l: nil},
              %MatchGraph{id: 9, type: :lm, round: 5, w: 11, l: nil},
              %MatchGraph{id: 10, type: :lm, round: 5, w: 11, l: nil},
              %MatchGraph{id: 11, type: :lr, round: 6, w: 12, l: nil},
              %MatchGraph{id: 12, type: :lm, round: 7, w: 13, l: nil},
              %MatchGraph{id: 13, type: :c, round: 8, w: 14, l: 14},
              %MatchGraph{id: 14, type: :c, round: 9, w: nil, l: nil}
            ]
          },
          "16 players" => %{
            size: 16,
            res: [
              %MatchGraph{id: 0, type: :w, round: 1, w: 8, l: 15},
              %MatchGraph{id: 1, type: :w, round: 1, w: 8, l: 15},
              %MatchGraph{id: 2, type: :w, round: 1, w: 9, l: 16},
              %MatchGraph{id: 3, type: :w, round: 1, w: 9, l: 16},
              %MatchGraph{id: 4, type: :w, round: 1, w: 10, l: 17},
              %MatchGraph{id: 5, type: :w, round: 1, w: 10, l: 17},
              %MatchGraph{id: 6, type: :w, round: 1, w: 11, l: 18},
              %MatchGraph{id: 7, type: :w, round: 1, w: 11, l: 18},
              %MatchGraph{id: 8, type: :w, round: 2, w: 12, l: 22},
              %MatchGraph{id: 9, type: :w, round: 2, w: 12, l: 21},
              %MatchGraph{id: 10, type: :w, round: 2, w: 13, l: 20},
              %MatchGraph{id: 11, type: :w, round: 2, w: 13, l: 19},
              %MatchGraph{id: 12, type: :w, round: 3, w: 14, l: 26},
              %MatchGraph{id: 13, type: :w, round: 3, w: 14, l: 25},
              %MatchGraph{id: 14, type: :w, round: 4, w: 29, l: 28},
              %MatchGraph{id: 15, type: :lm, round: 5, w: 19, l: nil},
              %MatchGraph{id: 16, type: :lm, round: 5, w: 20, l: nil},
              %MatchGraph{id: 17, type: :lm, round: 5, w: 21, l: nil},
              %MatchGraph{id: 18, type: :lm, round: 5, w: 22, l: nil},
              %MatchGraph{id: 19, type: :lm, round: 6, w: 23, l: nil},
              %MatchGraph{id: 20, type: :lm, round: 6, w: 23, l: nil},
              %MatchGraph{id: 21, type: :lm, round: 6, w: 24, l: nil},
              %MatchGraph{id: 22, type: :lm, round: 6, w: 24, l: nil},
              %MatchGraph{id: 23, type: :lr, round: 7, w: 25, l: nil},
              %MatchGraph{id: 24, type: :lr, round: 7, w: 26, l: nil},
              %MatchGraph{id: 25, type: :lm, round: 8, w: 27, l: nil},
              %MatchGraph{id: 26, type: :lm, round: 8, w: 27, l: nil},
              %MatchGraph{id: 27, type: :lr, round: 9, w: 28, l: nil},
              %MatchGraph{id: 28, type: :lm, round: 10, w: 29, l: nil},
              %MatchGraph{id: 29, type: :c, round: 11, w: 30, l: 30},
              %MatchGraph{id: 30, type: :c, round: 12, w: nil, l: nil}
            ]
          }
        } do
      @tag params: params
      test name, %{params: params} do
        assert MatchGraph.generate(params.size) == params.res
      end
    end
  end
end
