defmodule Elchesser.Fen do
  alias Elchesser.{Piece, Square, Game}

  @spec parse(String.t()) :: Elchesser.Game.t()
  def parse(fen) do
    [board, color, castling, en_passant, half_moves, full_moves] = String.split(fen, " ")

    with {:ok, board} <- parse_board(board),
         {:ok, active} <- parse_color(color),
         {:ok, castling} <- parse_castling(castling),
         {:ok, en_passant} <- parse_en_passant(en_passant),
         {:ok, half_moves} <- parse_half_moves(half_moves),
         {:ok, full_moves} <- parse_full_moves(full_moves) do
      game = %Elchesser.Game{
        board: board,
        active: active,
        castling: castling,
        en_passant: en_passant,
        half_moves: half_moves,
        full_moves: full_moves
      }

      %Game{game | check: Game.Check.check?(game)}
    end
  end

  defp parse_board(board_string) do
    board =
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

    {:ok, board}
  end

  defp parse_color("w"), do: {:ok, :w}
  defp parse_color("b"), do: {:ok, :b}

  defp parse_castling("-"), do: {:ok, MapSet.new()}

  defp parse_castling(castling_str) do
    {:ok,
     castling_str
     |> String.graphemes()
     |> Enum.map(&String.to_atom/1)
     |> Enum.filter(&(&1 in [:K, :k, :Q, :q]))
     |> Enum.into(MapSet.new())}
  end

  defp parse_en_passant("-"), do: {:ok, nil}

  defp parse_en_passant(<<file, rank::8>>),
    do: {:ok, Square.from(file, rank - 48, nil)}

  defp parse_half_moves(h) do
    case Integer.parse(h) do
      :error -> {:error, :invalid_half_move}
      {n, _} -> {:ok, n}
    end
  end

  defp parse_full_moves(f) do
    case Integer.parse(f) do
      :error -> {:error, :invalid_full_move}
      {n, _} -> {:ok, n}
    end
  end
end
