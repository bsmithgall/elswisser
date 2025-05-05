defmodule Elchesser.Pgn.ParserHelpers do
  import NimbleParsec

  def tag_name, do: utf8_string([?0..?9, ?a..?z, ?A..?Z, ?_], min: 1)
  def tag_value, do: utf8_string([not: ?\\, not: ?"], min: 0) |> label("tag_value")

  def tag do
    ignore(eventually(ascii_char(~c"[")))
    |> ignore(repeat(ascii_char([?\s])))
    |> concat(tag_name())
    |> ignore(repeat(ascii_char([?\s])))
    |> ignore(ascii_char(~c'"'))
    |> concat(tag_value())
    |> ignore(eventually(ascii_char(~c"]")))
    |> wrap
  end

  def move_number do
    integer(min: 1, max: 3)
    |> repeat(ascii_char(~c"."))
    |> repeat(ascii_char(~c" "))
  end

  def comment, do: string("{") |> eventually(string("}"))
  def whitespace, do: ascii_char(~c"\n\s\r")

  def termination_marker do
    choice([
      string("1-0") |> replace(:white),
      string("0-1") |> replace(:black),
      string("1/2-1/2") |> replace(:draw),
      string("*") |> replace(nil)
    ])
  end

  def move_text,
    do: utf8_string([not: ?\n, not: ?\s, not: ?\r, not: ?\t, not: ??, not: ?!], min: 2)

  def annotation, do: ascii_char(~c"?!")

  def comments, do: optional(whitespace()) |> concat(comment())

  def alternates do
    optional(whitespace())
    |> concat(string("(") |> eventually(string(")")))
  end

  # In older chesscom PGNs, sometimes you get this strange stuff. Probably a bug on their end.
  def weird_chesscom_errata,
    do: optional(whitespace()) |> concat(string("$")) |> concat(ascii_char([?0..?9]))

  def move do
    optional(ignore(repeat(whitespace())))
    |> optional(ignore(move_number()))
    |> optional(ignore(repeat(whitespace())))
    |> concat(move_text())
    |> optional(ignore(weird_chesscom_errata()))
    |> optional(ignore(repeat(annotation())))
    |> optional(ignore(repeat(comments())))
    |> optional(ignore(repeat(alternates())))
    |> optional(ignore(concat(repeat(whitespace()), termination_marker())))
  end

  def tag_pairs, do: tag() |> times(min: 7) |> ignore(repeat(ascii_char(~c"\r\n"))) |> optional()

  def moves do
    move()
    |> optional(move())
    |> repeat()
    |> ignore(repeat(ascii_char(~c"\r\n")))
  end

  def result, do: eventually(termination_marker()) |> ignore(repeat(whitespace()))
end
