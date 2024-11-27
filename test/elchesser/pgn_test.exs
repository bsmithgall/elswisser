defmodule Elchesser.PgnTest do
  use ExUnit.Case, async: true

  alias Elchesser.Game

  test "works as expected with weird chesscom errata" do
    {:ok, game} =
      Elchesser.Pgn.parse("""
      [Event "Live Chess"]
      [Site "Chess.com"]
      [Date "2021.09.19"]
      [Round "-"]
      [White "FloatingOcean23"]
      [Black "TaoTehKing"]
      [Result "1-0"]
      [CurrentPosition "2Q1R3/p4p1p/1q1b4/1kpp4/P7/1PB2N2/2PP1PPP/R5K1 b - -"]
      [Timezone "UTC"]
      [ECO "C00"]
      [ECOUrl "https://www.chess.com/openings/French-Defense-Horwitz-Papa-Ticulat-Gambit"]
      [UTCDate "2021.09.19"]
      [UTCTime "19:23:48"]
      [WhiteElo "1512"]
      [BlackElo "1505"]
      [TimeControl "180"]
      [Termination "FloatingOcean23 won by checkmate"]
      [StartTime "19:23:48"]
      [EndDate "2021.09.19"]
      [EndTime "19:26:19"]
      [Link "https://www.chess.com/game/live/25818550749"]

      1. e4 e6 2. b3 d5 3. Bb2 c5 4. Nf3 Nc6 5. exd5 exd5 6. Bb5 Qb6 $6 7. Bxc6+ bxc6 $6
      8. O-O Ba6 $2 9. Re1+ Ne7 10. Nc3 O-O-O $6 11. Na4 Qc7 12. Nxc5 Nf5 13. Nxa6 Qb6
      14. Qe2 Bd6 $6 15. a3 Rhe8 16. Qd3 Nh6 17. Bxg7 Ng4 18. Qf5+ Rd7 19. Rxe8+ Kb7
      20. Qxd7+ Kxa6 21. Qxg4 c5 22. Qc8+ Ka5 23. Bc3+ Kb5 $6 24. a4# 1-0
      """)

    assert game.result == :white
    assert Game.get_square(game, {?a, 4}).piece == :P
    assert length(game.moves) == 47
  end

  test "works as expected with all the crazy chesscom options enabled" do
    {:ok, game} =
      Elchesser.Pgn.parse("""
      [Event "Live Chess"]
      [Site "Chess.com"]
      [Date "2024.05.23"]
      [Round "-"]
      [White "FloatingOcean23"]
      [Black "gshdhdjdjhdjdj"]
      [Result "1-0"]
      [CurrentPosition "4r1k1/qpp2p2/2np1p1Q/1p3N2/4P3/1P1P4/1PP3PP/5R1K b - -"]
      [Timezone "UTC"]
      [ECO "C28"]
      [ECOUrl "https://www.chess.com/openings/Bishops-Opening-Berlin-Vienna-Hybrid-Variation-4...Bc5-5.f4"]
      [UTCDate "2024.05.23"]
      [UTCTime "14:46:42"]
      [WhiteElo "1707"]
      [BlackElo "1671"]
      [TimeControl "180"]
      [Termination "FloatingOcean23 won by resignation"]
      [StartTime "14:46:42"]
      [EndDate "2024.05.23"]
      [EndTime "14:48:36"]
      [Link "https://www.chess.com/game/live/110214653711"]
      [WhiteUrl "https://images.chesscomfiles.com/uploads/v1/user/87160048.aee8e921.50x50o.cdf8347acc90.jpeg"]
      [WhiteCountry "2"]
      [WhiteTitle ""]
      [BlackUrl "https://www.chess.com/bundles/web/images/noavatar_l.84a92436.gif"]
      [BlackCountry "176"]
      [BlackTitle ""]

      1. e4 {[%clk 0:03:00]} 1... e5 {[%clk 0:03:00]} 2. Nc3 {[%clk 0:02:59.1]} 2...
      Nc6 {[%clk 0:02:59.9]} 3. Bc4 {[%clk 0:02:58.4]} 3... Nf6 {[%clk 0:02:59.4]} 4.
      d3 {[%clk 0:02:57.3]} 4... Bc5 {[%clk 0:02:58.7]} 5. f4 {[%clk 0:02:56.1]} 5...
      exf4 {[%clk 0:02:56.2]} 6. Bxf4 {[%clk 0:02:56]} 6... d6 {[%clk 0:02:55.4]} 7.
      Na4 $6 {[%clk 0:02:54.6][%c_effect
      a4;square;a4;type;Inaccuracy;path;null;size;100%25;animated;false;persistent;true]}
      7... Bb6 $2 {[%clk 0:02:52.3][%c_effect
      b6;square;b6;type;Mistake;path;null;size;100%25;animated;false;persistent;true]}
      8. Nxb6 {[%clk 0:02:53.6]} 8... axb6 {[%clk 0:02:52.2]} 9. Nf3 {[%clk
      0:02:52.8]} 9... Be6 {[%clk 0:02:51.5]} 10. O-O $2 {[%clk 0:02:43.7][%c_effect
      g1;square;g1;type;Mistake;path;null;size;100%25;animated;false;persistent;true]}
      10... O-O {[%clk 0:02:48.9][%c_effect
      g8;square;g8;type;Miss;path;null;size;100%25;animated;false;persistent;true]}
      11. Bb3 $6 {[%clk 0:02:41.7][%c_effect
      b3;square;b3;type;Inaccuracy;path;null;size;100%25;animated;false;persistent;true]}
      11... Bxb3 {[%clk 0:02:40.5]} 12. axb3 {[%clk 0:02:41.6]} 12... Re8 $6 {[%clk
      0:02:37.9][%c_effect
      e8;square;e8;type;Inaccuracy;path;null;size;100%25;animated;false;persistent;true]}
      13. Bg5 $6 {[%clk 0:02:40.3][%c_effect
      g5;square;g5;type;Inaccuracy;path;null;size;100%25;animated;false;persistent;true]}
      13... h6 $2 {[%clk 0:02:35.9][%c_effect
      h6;square;h6;type;Mistake;path;null;size;100%25;animated;false;persistent;true]}
      14. Rxa8 $1 {[%clk 0:02:34.2][%c_effect
      a8;square;a8;type;GreatFind;path;null;size;100%25;animated;false;persistent;true]}
      14... Qxa8 {[%clk 0:02:32.5]} 15. Bxf6 {[%clk 0:02:33.3]} 15... gxf6 {[%clk
      0:02:31.3]} 16. Qd2 $6 {[%clk 0:02:31.8][%c_effect
      d2;square;d2;type;Inaccuracy;path;null;size;100%25;animated;false;persistent;true]}
      16... Kg7 $6 {[%clk 0:02:29.9][%c_effect
      g7;square;g7;type;Inaccuracy;path;null;size;100%25;animated;false;persistent;true]}
      17. Nh4 {[%clk 0:02:29.2]} 17... Qa7 $2 {[%clk 0:02:16.7][%c_effect
      a7;square;a7;type;Mistake;path;null;size;100%25;animated;false;persistent;true]}
      18. Nf5+ $1 {[%clk 0:02:28.2][%c_effect
      f5;square;f5;type;GreatFind;path;null;size;100%25;animated;false;persistent;true]}
      18... Kg8 {[%clk 0:02:09.7]} 19. Qxh6 {[%clk 0:02:22.2]} 19... b5+ {[%clk
      0:02:02.4]} 20. Kh1 {[%clk 0:02:21.4][%c_effect
      h1;square;h1;type;Winner,g8;square;g8;type;ResignBlack]} 1-0
      """)

    assert game.result == :white
    assert Game.get_square(game, {?h, 1}).piece == :K
    assert length(game.moves) == 39
  end

  test "works as expected with Lichess annotations" do
    {:ok, game} =
      Elchesser.Pgn.parse("""
      [Event "FIDE Candidates 2024"]
      [Site "Toronto, Canada"]
      [Date "2024.04.04"]
      [Round "1"]
      [White "Caruana, Fabiano"]
      [Black "Nakamura, Hikaru"]
      [Result "1/2-1/2"]
      [WhiteElo "2803"]
      [WhiteTitle "GM"]
      [WhiteFideId "2020009"]
      [BlackElo "2789"]
      [BlackTitle "GM"]
      [BlackFideId "2016192"]
      [TimeControl "40/7200:1800+30"]
      [Variant "Standard"]
      [ECO "B56"]
      [Opening "Sicilian Defense: Venice Attack"]
      [Annotator "https://lichess.org/broadcast/-/-/AjqSsU1w"]

      1. e4 { [%eval 0.14] [%clk 1:59:56] } 1... c5 { [%eval 0.17] [%clk 1:59:50] } 2. Nf3 { [%eval 0.22] [%clk 1:59:51] } 2... d6 { [%eval 0.0] [%clk 1:59:46] } 3. d4 { [%eval 0.18] [%clk 1:59:37] } 3... cxd4 { [%eval 0.13] [%clk 1:59:40] } 4. Nxd4 { [%eval 0.27] [%clk 1:59:34] } 4... Nf6 { [%eval 0.3] [%clk 1:59:34] } 5. Nc3 { [%eval 0.21] [%clk 1:59:30] } 5... e5 { [%eval 0.4] [%clk 1:59:29] } 6. Bb5+ { [%eval 0.68] [%clk 1:55:46] } 6... Nbd7 { [%eval 0.48] [%clk 1:58:59] } 7. Nf5 { [%eval 0.42] [%clk 1:51:39] } 7... a6 { [%eval 0.37] [%clk 1:58:16] } 8. Ba4 { [%eval 0.53] [%clk 1:42:19] } 8... b5 { [%eval 0.52] [%clk 1:58:02] } 9. Bb3 { [%eval 0.58] [%clk 1:42:16] } 9... Nc5 { [%eval 0.52] [%clk 1:57:57] } 10. Bg5 { [%eval 0.51] [%clk 1:40:36] } 10... Bxf5 { [%eval 0.6] [%clk 1:57:51] } 11. exf5 { [%eval 0.51] [%clk 1:38:42] } 11... Be7 { [%eval 0.64] [%clk 1:57:46] } 12. Bxf6 { [%eval 0.48] [%clk 1:33:12] } 12... Bxf6 { [%eval 0.54] [%clk 1:56:03] } 13. O-O { [%eval 0.41] [%clk 1:22:58] } 13... e4 { [%eval 0.4] [%clk 1:53:20] } 14. Nxe4 { [%eval 0.4] [%clk 1:13:23] } 14... Nxe4 { [%eval 0.41] [%clk 1:52:04] } 15. Re1 { [%eval 0.25] [%clk 1:13:03] } 15... O-O { [%eval 0.29] [%clk 1:51:56] } 16. Rxe4 { [%eval 0.32] [%clk 1:13:00] } 16... Bxb2 { [%eval 0.34] [%clk 1:51:42] } 17. Rb1 { [%eval 0.33] [%clk 1:12:58] } 17... Bf6 { [%eval 0.47] [%clk 1:47:50] } 18. Qd5 { [%eval 0.29] [%clk 1:10:20] } 18... Rc8 { [%eval 0.28] [%clk 1:41:13] } 19. Qb7 { [%eval 0.28] [%clk 0:57:51] } 19... Rc5 { [%eval 0.46] [%clk 1:06:46] } 20. Qxa6 { [%eval 0.39] [%clk 0:56:30] } 20... Rxf5 { [%eval 0.51] [%clk 1:02:19] } 21. Rd1 { [%eval 0.21] [%clk 0:51:45] } 21... d5 { [%eval 0.39] [%clk 0:59:30] } 22. Rb4 { [%eval 0.36] [%clk 0:30:49] } 22... Bc3?! { [%eval 1.22] } { Inaccuracy. Qe7 was best. } { [%clk 0:39:20] } (22... Qe7) 23. Rxb5 { [%eval 1.29] [%clk 0:30:26] } 23... Rxf2 { [%eval 1.29] [%clk 0:39:13] } 24. Rbxd5 { [%eval 1.17] [%clk 0:20:08] } 24... Qh4 { [%eval 1.36] [%clk 0:38:42] } 25. Qd3 { [%eval 1.3] [%clk 0:17:37] } 25... Rf6 { [%eval 1.55] [%clk 0:35:57] } 26. g3 { [%eval 1.48] [%clk 0:15:07] } 26... Qb4 { [%eval 1.38] [%clk 0:35:21] } 27. Kg2 { [%eval 1.14] [%clk 0:12:19] } 27... Bb2 { [%eval 1.39] [%clk 0:33:45] } 28. Rf5?! { [%eval 0.49] } { Inaccuracy. Rf1 was best. } { [%clk 0:09:21] } (28. Rf1 Rxf1) 28... g6 { [%eval 0.92] [%clk 0:22:58] } 29. Rxf6?! { [%eval 0.29] } { Inaccuracy. Rb5 was best. } { [%clk 0:09:18] } (29. Rb5) 29... Bxf6 { [%eval 0.26] [%clk 0:22:54] } 30. Qf3 { [%eval 0.1] [%clk 0:09:01] } 30... Qe7 { [%eval 0.17] [%clk 0:22:50] } 31. a4 { [%eval 0.11] [%clk 0:08:05] } 31... Kg7 { [%eval 0.08] [%clk 0:21:22] } 32. a5 { [%eval 0.0] [%clk 0:07:49] } 32... Ra8 { [%eval 0.0] [%clk 0:18:27] } 33. Rd5 { [%eval 0.0] [%clk 0:06:46] } 33... Ra7 { [%eval 0.0] [%clk 0:18:22] } 34. Rb5 { [%eval 0.0] [%clk 0:05:08] } 34... Qd8 { [%eval 0.0] [%clk 0:16:57] } 35. Rd5 { [%eval 0.0] [%clk 0:04:14] } 35... Qc7 { [%eval 0.0] [%clk 0:15:22] } 36. h4 { [%eval 0.0] [%clk 0:03:22] } 36... Rxa5 { [%eval 0.12] [%clk 0:09:07] } 37. Rxa5 { [%eval 0.07] [%clk 0:03:18] } 37... Qxa5 { [%eval 0.06] [%clk 0:09:04] } 38. Qb7 { [%eval 0.06] [%clk 0:03:15] } 38... Qd8 { [%eval 0.1] [%clk 0:08:42] } 39. Qxf7+ { [%eval 0.09] [%clk 0:03:09] } 39... Kh6 { [%eval 0.08] [%clk 0:08:41] } 40. Kh3 { [%eval 0.1] [%clk 0:32:02] } 40... Qe7 { [%eval 0.46] [%clk 0:38:54] } 41. Qc4 { [%eval 0.11] [%clk 0:31:46] } 41... Qe3 { [%eval 0.12] [%clk 0:38:49] } 1/2-1/2
      """)

    assert game.result == :draw
    assert Game.get_square(game, {?e, 3}).piece == :q
    assert length(game.moves) == 82
  end

  describe "to_move_list/1" do
    test "works as expected" do
      {:ok, game} =
        Elchesser.Pgn.parse("""
        [Event "FIDE Candidates 2024"]
        [Site "Toronto, Canada"]
        [Date "2024.04.04"]
        [Round "1"]
        [White "Caruana, Fabiano"]
        [Black "Nakamura, Hikaru"]
        [Result "1/2-1/2"]
        [WhiteElo "2803"]
        [WhiteTitle "GM"]
        [WhiteFideId "2020009"]
        [BlackElo "2789"]
        [BlackTitle "GM"]
        [BlackFideId "2016192"]
        [TimeControl "40/7200:1800+30"]
        [Variant "Standard"]
        [ECO "B56"]
        [Opening "Sicilian Defense: Venice Attack"]
        [Annotator "https://lichess.org/broadcast/-/-/AjqSsU1w"]

        1. e4 { [%eval 0.14] [%clk 1:59:56] } 1... c5 { [%eval 0.17] [%clk 1:59:50] } 2. Nf3 { [%eval 0.22] [%clk 1:59:51] } 2... d6 { [%eval 0.0] [%clk 1:59:46] } 3. d4 { [%eval 0.18] [%clk 1:59:37] } 3... cxd4 { [%eval 0.13] [%clk 1:59:40] } 4. Nxd4 { [%eval 0.27] [%clk 1:59:34] } 4... Nf6 { [%eval 0.3] [%clk 1:59:34] } 5. Nc3 { [%eval 0.21] [%clk 1:59:30] } 5... e5 { [%eval 0.4] [%clk 1:59:29] } 6. Bb5+ { [%eval 0.68] [%clk 1:55:46] } 6... Nbd7 { [%eval 0.48] [%clk 1:58:59] } 7. Nf5 { [%eval 0.42] [%clk 1:51:39] } 7... a6 { [%eval 0.37] [%clk 1:58:16] } 8. Ba4 { [%eval 0.53] [%clk 1:42:19] } 8... b5 { [%eval 0.52] [%clk 1:58:02] } 9. Bb3 { [%eval 0.58] [%clk 1:42:16] } 9... Nc5 { [%eval 0.52] [%clk 1:57:57] } 10. Bg5 { [%eval 0.51] [%clk 1:40:36] } 10... Bxf5 { [%eval 0.6] [%clk 1:57:51] } 11. exf5 { [%eval 0.51] [%clk 1:38:42] } 11... Be7 { [%eval 0.64] [%clk 1:57:46] } 12. Bxf6 { [%eval 0.48] [%clk 1:33:12] } 12... Bxf6 { [%eval 0.54] [%clk 1:56:03] } 13. O-O { [%eval 0.41] [%clk 1:22:58] } 13... e4 { [%eval 0.4] [%clk 1:53:20] } 14. Nxe4 { [%eval 0.4] [%clk 1:13:23] } 14... Nxe4 { [%eval 0.41] [%clk 1:52:04] } 15. Re1 { [%eval 0.25] [%clk 1:13:03] } 15... O-O { [%eval 0.29] [%clk 1:51:56] } 16. Rxe4 { [%eval 0.32] [%clk 1:13:00] } 16... Bxb2 { [%eval 0.34] [%clk 1:51:42] } 17. Rb1 { [%eval 0.33] [%clk 1:12:58] } 17... Bf6 { [%eval 0.47] [%clk 1:47:50] } 18. Qd5 { [%eval 0.29] [%clk 1:10:20] } 18... Rc8 { [%eval 0.28] [%clk 1:41:13] } 19. Qb7 { [%eval 0.28] [%clk 0:57:51] } 19... Rc5 { [%eval 0.46] [%clk 1:06:46] } 20. Qxa6 { [%eval 0.39] [%clk 0:56:30] } 20... Rxf5 { [%eval 0.51] [%clk 1:02:19] } 21. Rd1 { [%eval 0.21] [%clk 0:51:45] } 21... d5 { [%eval 0.39] [%clk 0:59:30] } 22. Rb4 { [%eval 0.36] [%clk 0:30:49] } 22... Bc3?! { [%eval 1.22] } { Inaccuracy. Qe7 was best. } { [%clk 0:39:20] } (22... Qe7) 23. Rxb5 { [%eval 1.29] [%clk 0:30:26] } 23... Rxf2 { [%eval 1.29] [%clk 0:39:13] } 24. Rbxd5 { [%eval 1.17] [%clk 0:20:08] } 24... Qh4 { [%eval 1.36] [%clk 0:38:42] } 25. Qd3 { [%eval 1.3] [%clk 0:17:37] } 25... Rf6 { [%eval 1.55] [%clk 0:35:57] } 26. g3 { [%eval 1.48] [%clk 0:15:07] } 26... Qb4 { [%eval 1.38] [%clk 0:35:21] } 27. Kg2 { [%eval 1.14] [%clk 0:12:19] } 27... Bb2 { [%eval 1.39] [%clk 0:33:45] } 28. Rf5?! { [%eval 0.49] } { Inaccuracy. Rf1 was best. } { [%clk 0:09:21] } (28. Rf1 Rxf1) 28... g6 { [%eval 0.92] [%clk 0:22:58] } 29. Rxf6?! { [%eval 0.29] } { Inaccuracy. Rb5 was best. } { [%clk 0:09:18] } (29. Rb5) 29... Bxf6 { [%eval 0.26] [%clk 0:22:54] } 30. Qf3 { [%eval 0.1] [%clk 0:09:01] } 30... Qe7 { [%eval 0.17] [%clk 0:22:50] } 31. a4 { [%eval 0.11] [%clk 0:08:05] } 31... Kg7 { [%eval 0.08] [%clk 0:21:22] } 32. a5 { [%eval 0.0] [%clk 0:07:49] } 32... Ra8 { [%eval 0.0] [%clk 0:18:27] } 33. Rd5 { [%eval 0.0] [%clk 0:06:46] } 33... Ra7 { [%eval 0.0] [%clk 0:18:22] } 34. Rb5 { [%eval 0.0] [%clk 0:05:08] } 34... Qd8 { [%eval 0.0] [%clk 0:16:57] } 35. Rd5 { [%eval 0.0] [%clk 0:04:14] } 35... Qc7 { [%eval 0.0] [%clk 0:15:22] } 36. h4 { [%eval 0.0] [%clk 0:03:22] } 36... Rxa5 { [%eval 0.12] [%clk 0:09:07] } 37. Rxa5 { [%eval 0.07] [%clk 0:03:18] } 37... Qxa5 { [%eval 0.06] [%clk 0:09:04] } 38. Qb7 { [%eval 0.06] [%clk 0:03:15] } 38... Qd8 { [%eval 0.1] [%clk 0:08:42] } 39. Qxf7+ { [%eval 0.09] [%clk 0:03:09] } 39... Kh6 { [%eval 0.08] [%clk 0:08:41] } 40. Kh3 { [%eval 0.1] [%clk 0:32:02] } 40... Qe7 { [%eval 0.46] [%clk 0:38:54] } 41. Qc4 { [%eval 0.11] [%clk 0:31:46] } 41... Qe3 { [%eval 0.12] [%clk 0:38:49] } 1/2-1/2
        """)

      assert Elchesser.Pgn.to_move_list(game) ==
               "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 e5 6. Bb5+ Nbd7 7. Nf5 a6 8. Ba4 b5 9. Bb3 Nc5 10. Bg5 Bxf5 11. exf5 Be7 12. Bxf6 Bxf6 13. O-O e4 14. Nxe4 Nxe4 15. Re1 O-O 16. Rxe4 Bxb2 17. Rb1 Bf6 18. Qd5 Rc8 19. Qb7 Rc5 20. Qxa6 Rxf5 21. Rd1 d5 22. Rb4 Bc3 23. Rxb5 Rxf2 24. Rbxd5 Qh4 25. Qd3 Rf6 26. g3 Qb4 27. Kg2 Bb2 28. Rf5 g6 29. Rxf6 Bxf6 30. Qf3 Qe7 31. a4 Kg7 32. a5 Ra8 33. Rd5 Ra7 34. Rb5 Qd8 35. Rd5 Qc7 36. h4 Rxa5 37. Rxa5 Qxa5 38. Qb7 Qd8 39. Qxf7+ Kh6 40. Kh3 Qe7 41. Qc4 Qe3"
    end
  end
end
