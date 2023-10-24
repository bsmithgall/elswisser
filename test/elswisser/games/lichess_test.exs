defmodule Elswisser.Games.LichessTest do
  use ExUnit.Case, async: true

  alias Elswisser.Games.Lichess

  test "extract_id/1 works for normal format" do
    assert Lichess.extract_id("https://lichess.org/1234") == {:ok, "1234"}
  end

  test "extract_id/1 works for format from black perspective" do
    assert Lichess.extract_id("https://lichess.org/1234") == {:ok, "1234"}
  end

  test "extract_id/1 handles missing IDs well enough" do
    assert Lichess.extract_id("https://lichess.org/") ==
             {:error, "Could not find game ID in game link!"}
  end
end
