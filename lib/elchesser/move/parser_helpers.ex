defmodule Elchesser.Move.ParserHelpers do
  import NimbleParsec

  @pieces ~c"RNBQK"

  def piece, do: ascii_char(@pieces) |> label("piece")
  def file, do: ascii_char([Elchesser.files()]) |> label("f")
  def rank, do: ascii_char([Elchesser.ranks_c()]) |> label("rank")

  def loc, do: concat(file(), rank()) |> label("Location")
  def castle_queenside, do: string("O-O-O") |> replace(:queenside)
  def castle_kingside, do: string("O-O") |> lookahead_not(string("-O")) |> replace(:kingside)

  def capture do
    ascii_char(~c"x") |> label("takes") |> replace(true) |> unwrap_and_tag(:capture)
  end

  def check do
    ascii_char(~c"+") |> label("check") |> replace(:check) |> unwrap_and_tag(:checking)
  end

  def checkmate do
    ascii_char(~c"#") |> label("mate") |> replace(:checkmate) |> unwrap_and_tag(:checking)
  end

  def promote do
    ascii_char(~c"=") |> ignore() |> label("promote") |> concat(piece()) |> tag(:promotion)
  end

  def pawn_move do
    optional(choice([file(), rank()]) |> tag(:from) |> lookahead(choice([capture(), loc()])))
    |> optional(capture())
    |> concat(loc() |> tag(:to))
    |> optional(promote())
    |> optional(choice([check(), checkmate()]))
  end

  def piece_move do
    tag(piece(), :piece)
    |> optional(
      choice([loc(), file(), rank()])
      |> tag(:from)
      |> lookahead(choice([capture(), loc()]))
    )
    |> optional(capture())
    |> concat(loc() |> tag(:to))
    |> optional(choice([check(), checkmate()]))
  end

  def castling, do: choice([castle_kingside(), castle_queenside()]) |> unwrap_and_tag(:castling)

  def parse_move, do: choice([pawn_move(), piece_move(), castling()])
end
