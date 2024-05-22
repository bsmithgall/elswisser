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

  @spec dump(Game.t()) :: binary()
  def dump(%Game{board: board, active: active, castling: castling, en_passant: en_passant} = game) do
    "#{dump_board(board)} #{dump_active(active)} #{dump_castling(castling)} #{dump_en_passant(en_passant)} #{game.half_moves} #{game.full_moves}"
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

  defp dump_board(%{} = board) do
    for rank <- Elchesser.ranks(), file <- Elchesser.files() do
      Map.get(board, {file, rank})
    end
    |> Enum.chunk_every(8)
    |> Enum.reverse()
    |> Enum.map(fn rank ->
      Enum.reduce(rank, {0, ""}, fn square, {ct, acc} ->
        case square.piece do
          nil -> {ct + 1, acc}
          p -> {0, acc <> dump_pieces(ct, p)}
        end
      end)
      |> then(fn {ct, acc} -> if ct == 8, do: "8", else: acc end)
    end)
    |> Enum.join("/")
  end

  def dump_pieces(0, piece), do: Atom.to_string(piece)
  def dump_pieces(int, piece), do: Integer.to_string(int) <> Atom.to_string(piece)

  defp dump_active(:w), do: "w"
  defp dump_active(:b), do: "b"

  defp dump_castling(%MapSet{} = castling) when map_size(castling.map) == 0 do
    "-"
  end

  defp dump_castling(%MapSet{} = castling) do
    castling |> Enum.map(&Atom.to_string/1) |> Enum.sort() |> Enum.join("")
  end

  defp dump_en_passant(nil), do: "-"
  defp dump_en_passant({f, r}), do: <<f, r + 48>>
end
