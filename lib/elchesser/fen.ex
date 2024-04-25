defmodule Elchesser.Fen do
  alias Elchesser.Piece
  @start "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

  @spec parse(String.t()) :: Elchesser.Game.t()
  def parse(fen) do
    [board, _color, _castling, _en_passant, _half_clock, _full_moves] = String.split(fen, " ")

    %Elchesser.Game{
      board: parse_board(board)
    }
  end

  defp parse_board(board_string) do
    board_string
    |> String.split("/")
    |> Enum.reverse()
    |> Enum.with_index(1)
    |> Enum.reduce(Elchesser.Game.empty(), fn {fileStr, rank}, acc ->
      Map.merge(
        acc,
        String.graphemes(fileStr)
        |> Enum.reduce({?a, %{}}, fn c, {file, rankMap} ->
          case Integer.parse(c) do
            {n, _} ->
              {file + n,
               Map.merge(
                 rankMap,
                 file..(file + n) |> Enum.map(fn f -> {{f, rank}, nil} end) |> Enum.into(%{})
               )}

            :error ->
              {file + 1, Map.put(rankMap, {file, rank}, Piece.from_string(c))}
          end
        end)
        |> then(&elem(&1, 1))
      )
    end)
  end
end
