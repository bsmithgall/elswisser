defmodule Elswisser.Pairings.DoubleElim.MatchGraphTest do
  use ExUnit.Case, async: true

  alias Elswisser.Pairings.DoubleElim.MatchGraph

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
end
