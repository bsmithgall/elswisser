defmodule Elswisser.Pairings.SeedTest do
  use ExUnit.Case, async: true

  alias Elswisser.Pairings.Seed

  test "works as expected" do
    assert Seed.generate_seeds(16) == [
             {1, 16},
             {8, 9},
             {5, 12},
             {4, 13},
             {3, 14},
             {6, 11},
             {7, 10},
             {2, 15}
           ]
  end
end
