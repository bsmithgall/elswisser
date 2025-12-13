defmodule Elswisser.Games.ChesscomTest do
  use ExUnit.Case, async: true

  alias Elswisser.Games.Chesscom

  test "extract_id/1 works for game format" do
    assert Chesscom.extract_id("https://www.chess.com/game/1234") == {:ok, "1234"}
  end

  test "extract_id/1 works for game/live format" do
    assert Chesscom.extract_id("https://www.chess.com/game/live/1234") == {:ok, "1234"}
  end

  test "extract_id/1 works for live/game format" do
    assert Chesscom.extract_id("https://www.chess.com/live/game/1234") == {:ok, "1234"}
  end

  test "extract_id/1 works for analysis/game/live format" do
    assert Chesscom.extract_id("https://www.chess.com/analysis/game/live/1234?tab=analysis") ==
             {:ok, "1234"}
  end

  test "extract_id/1 handles missing IDs well enough" do
    assert Chesscom.extract_id("https://www.chess.com/there/is/no/id/here") ==
             {:error, "Could not find game ID in game link!"}
  end
end
