defmodule Elswisser.Games.PgnTagParserTest do
  use ExUnit.Case, async: true

  alias Elswisser.Games.PgnTagParser

  test "parse_eco/1 works as expected for chesscom pgn" do
    assert PgnTagParser.parse_eco("""
           [Event "Live Chess"]
           [Site "Chess.com"]
           [Date "2024.02.07"]
           [Round "?"]
           [White "theshark64"]
           [Black "FloatingOcean23"]
           [Result "0-1"]
           [ECO "D31"]
           [WhiteElo "1709"]
           [BlackElo "1704"]
           [TimeControl "180"]
           [EndTime "4:22:46 PST"]
           [Termination "FloatingOcean23 won on time"]

           1. d4 d5 2. c4 e6 3. Nc3 a6 4. Bf4 dxc4 5. a4 Nc6 6. e3 Na5 7. Nf3 Bd6 8. Ne5 Nf6 9. g4 Bxe5 10. Bxe5 Nc6 11. Bg3 Nd5 12. Bg2 O-O 13. O-O Nxc3 14. bxc3 Bd7 15. Rb1 Na5 16. Bxb7 Nxb7 17. Rxb7 Rc8 18. e4 Bc6 19. Rb1 Bxe4 20. Rb2 Bd3 21.  Re1 Rb8 22. Rxb8 Qxb8 23. Qd2 Qd8 24. Qf4 c6 25. h4 Qa5 26. Qd2 Qxa4 27. h5 Qc2 28. Qxc2 Bxc2 29. Ra1 Ra8 30. Ra5 Bd1 31. h6 Bxg4 32. hxg7 Bf5 33. Be5 h5 34. f4 h4 35. Kf2 h3 36. Kg3 Ra7 37. Bd6 Kxg7 38. Bc5 Ra8 0-1
           """) == {"D31", "Queen's Gambit Declined"}
  end

  test "parse_eco/1 works as expected for lichess pgn" do
    assert PgnTagParser.parse_eco("""
           [Event "Rated Blitz game"]
           [Site "https://lichess.org/7UA51BDk"]
           [Date "2024.01.19"]
           [White "GoldenGraham12"]
           [Black "Gianni_Rizzola"]
           [Result "1-0"]
           [UTCDate "2024.01.19"]
           [UTCTime "01:51:51"]
           [WhiteElo "1957"]
           [BlackElo "1895"]
           [WhiteRatingDiff "+4"]
           [BlackRatingDiff "-4"]
           [Variant "Standard"]
           [TimeControl "180+0"]
           [ECO "B01"]
           [Opening "Scandinavian Defense: Valencian Variation"]
           [Termination "Time forfeit"]

           1. e4 { [%clk 0:03:00] } 1... d5 { [%clk 0:03:00] } 2. exd5 { [%clk 0:02:59] } 2... Qxd5 { [%clk 0:02:59] } 3. Nc3 { [%clk 0:02:58] } 3... Qd8 { [%clk 0:02:59] } 4. d4 { [%clk 0:02:56] } 4... Bf5 { [%clk 0:02:58] } 5. Bc4 { [%clk 0:02:54] } 5... e6 { [%clk 0:02:57] } 6. Nf3 { [%clk 0:02:53] } 6... Nc6 { [%clk 0:02:57] } 7. Bb5 { [%clk 0:02:50] } 7... Bd6 { [%clk 0:02:54] } 8. O-O { [%clk 0:02:49] } 8... Ne7 { [%clk 0:02:53] } 9. Re1 { [%clk 0:02:48] } 9... O-O { [%clk 0:02:52] } 10. Bg5 { [%clk 0:02:46] } 10... f6 { [%clk 0:02:51] } 11. Bh4 { [%clk 0:02:45] } 11... Nb4 { [%clk 0:02:50] } 12. Rc1 { [%clk 0:02:36] } 12... c6 { [%clk 0:02:48] } 13. Ba4 { [%clk 0:02:35] } 13... b5 { [%clk 0:02:47] } 14. Bb3 { [%clk 0:02:34] } 14... a5 { [%clk 0:02:46] } 15. a3 { [%clk 0:02:33] } 15... a4 { [%clk 0:02:45] } 16. Bxe6+ { [%clk 0:02:28] } 16... Bxe6 { [%clk 0:02:43] } 17. Rxe6 { [%clk 0:02:25] } 17... Qd7 { [%clk 0:02:39] } 18. Re1 { [%clk 0:02:19] } 18... Nbd5 { [%clk 0:02:26] } 19. Nxd5 { [%clk 0:02:17] } 19... Nxd5 { [%clk 0:02:24] } 20. Bg3 { [%clk 0:02:13] } 20... Nf4 { [%clk 0:02:19] } 21. Qd2 { [%clk 0:02:08] } 21... g5 { [%clk 0:02:13] } 22. c3 { [%clk 0:02:04] } 22... Qf5 { [%clk 0:02:04] } 23. Qc2 { [%clk 0:02:00] } 23... Qd5 { [%clk 0:01:55] } 24. Qe4 { [%clk 0:01:56] } 24... Qf7 { [%clk 0:01:50] } 25. Qxc6 { [%clk 0:01:37] } 25... Rfd8 { [%clk 0:01:24] } 26. Rb1 { [%clk 0:01:20] } 26... Rab8 { [%clk 0:00:57] } 27. Rbd1 { [%clk 0:01:11] } 27... Qg6 { [%clk 0:00:48] } 28. Qe4 { [%clk 0:01:09] } 28... f5 { [%clk 0:00:45] } 29. Qc6 { [%clk 0:01:00] } 29... Rdc8 { [%clk 0:00:41] } 30. Qa6 { [%clk 0:00:52] } 30... Rd8 { [%clk 0:00:32] } 31. Ne5 { [%clk 0:00:44] } 31... Bxe5 { [%clk 0:00:27] } 32. Qxg6+ { [%clk 0:00:43] } 32... hxg6 { [%clk 0:00:21] } 33. dxe5 { [%clk 0:00:42] } 33... Ne6 { [%clk 0:00:17] } 34. f3 { [%clk 0:00:32] } 34... f4 { [%clk 0:00:16] } 35. Bf2 { [%clk 0:00:31] } 35... Rxd1 { [%clk 0:00:13] } 36. Rxd1 { [%clk 0:00:30] } 36... Rb7 { [%clk 0:00:12] } 37. Bd4 { [%clk 0:00:29] } 37... Kf7 { [%clk 0:00:11] } 38. Kf2 { [%clk 0:00:27] } 38... Ke7 { [%clk 0:00:11] } 39. g3 { [%clk 0:00:27] } 39... Rd7 { [%clk 0:00:10] } 40. Ke2 { [%clk 0:00:24] } 40... fxg3 { [%clk 0:00:06] } 41. hxg3 { [%clk 0:00:24] } 41... Ng7 { [%clk 0:00:03] } 42. Be3 { [%clk 0:00:22] } 1-0
           """) == {"B01", "Scandinavian"}
  end

  test "parse_eco/1 works as expected for an invalid pgn" do
    assert PgnTagParser.parse_eco("") == {nil, nil}
  end
end
