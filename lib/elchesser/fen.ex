defmodule Elchesser.Fen do
  alias Elchesser.{Piece, Square}

  # @start "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

  @spec parse(String.t()) :: Elchesser.Game.t()
  def parse(fen) do
    [board, color, castling, en_passant, _half_clock, _full_moves] = String.split(fen, " ")

    %Elchesser.Game{
      board: parse_board(board),
      active: parse_color(color),
      castling: parse_castling(castling),
      en_passant: parse_en_passant(en_passant)
    }
  end

  defp parse_board(board_string) do
    board_string
    |> String.split("/")
    |> Enum.reverse()
    |> Enum.with_index(1)
    |> Enum.reduce(Elchesser.Game.empty().board, fn {fileStr, rank}, acc ->
      Map.merge(
        acc,
        String.graphemes(fileStr)
        |> Enum.reduce({?a, %{}}, fn c, {file, rankMap} ->
          case Integer.parse(c) do
            {n, _} ->
              {file + n,
               Map.merge(
                 rankMap,
                 file..(file + n)
                 |> Enum.map(fn f -> {{f, rank}, Square.from(f, rank, nil)} end)
                 |> Enum.into(%{})
               )}

            :error ->
              {file + 1,
               Map.put(rankMap, {file, rank}, Square.from(file, rank, Piece.from_string(c)))}
          end
        end)
        |> then(&elem(&1, 1))
      )
    end)
  end

  defp parse_color("w"), do: :w
  defp parse_color("b"), do: :b

  defp parse_castling("-"), do: MapSet.new()

  defp parse_castling(castling_str) do
    castling_str
    |> String.graphemes()
    |> Enum.map(&String.to_atom/1)
    |> Enum.filter(&(&1 in [:K, :k, :Q, :q]))
    |> Enum.into(MapSet.new())
  end

  defp parse_en_passant("-"), do: nil

  defp parse_en_passant(<<file, rank::8>>),
    do: Square.from(file, rank - 48, nil)
end
