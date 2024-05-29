defmodule Elchesser.Move.SanParser do
  alias __MODULE__
  alias Elchesser.{Game, Move, Piece, Board, Square}

  import Elchesser, only: [in_ranks: 1, in_files: 1]
  import NimbleParsec
  import Elchesser.Move.ParserHelpers

  defstruct from: nil,
            to: nil,
            piece: nil,
            capture: false,
            checking: nil,
            promotion: nil,
            castling: nil

  defparsecp(:move, parse_move())

  @spec parse(binary(), Game.t()) :: {:ok, Move.t()} | {:error, atom()}
  def parse(san, %Game{} = game) do
    with {:ok, tags, _, _, _, _} <- move(san) do
      {:ok, Map.merge(%SanParser{}, Enum.into(tags, %{})) |> to_move(game)}
    else
      _ -> {:error, :invalid_move}
    end
  end

  defp to_move(%SanParser{castling: :queenside}, %Game{active: :w}) do
    Move.from({?e, 1, :K}, {?c, 1}, castle: true)
  end

  defp to_move(%SanParser{castling: :queenside}, %Game{active: :b}) do
    Move.from({?e, 8, :k}, {?c, 8}, castle: true)
  end

  defp to_move(%SanParser{castling: :kingside}, %Game{active: :w}) do
    Move.from({?e, 1, :K}, {?g, 1}, castle: true)
  end

  defp to_move(%SanParser{castling: :kingside}, %Game{active: :b}) do
    Move.from({?e, 8, :k}, {?g, 8}, castle: true)
  end

  defp to_move(%SanParser{} = parsed, %Game{} = game) do
    partial_from = parse_loc(parsed.from)

    parsed =
      %{
        parsed
        | to: parse_loc(parsed.to),
          piece: parse_piece(parsed.piece, game),
          promotion: parse_promotion(parsed.promotion, game)
      }

    %Move{
      from: find_from(parsed, game, partial_from),
      to: parsed.to,
      piece: parsed.piece,
      promotion: parsed.promotion,
      capture: find_capture(parsed, game),
      castle: castles?(parsed),
      checking: parsed.checking
    }
  end

  defp parse_piece(nil, %Game{active: :w}), do: :P
  defp parse_piece(nil, %Game{active: :b}), do: :p

  defp parse_piece(p, %Game{active: active}) when is_list(p) do
    str = List.to_string(p)
    str = if(active == :b, do: String.downcase(str), else: str)
    Piece.from_string(str)
  end

  defp parse_promotion(nil, _), do: nil
  defp parse_promotion(piece, game), do: parse_piece(piece, game)

  defp parse_loc([file, rank] = l) when length(l) == 2, do: {file, rank - 48}
  # for move disambiguation
  defp parse_loc([c]) when in_ranks(c), do: {nil, c - 48}
  defp parse_loc([c]) when in_files(c), do: {c, nil}
  defp parse_loc(_), do: {nil, nil}

  defp find_from(%SanParser{piece: piece, to: to}, %Game{} = game, {from_file, from_rank}) do
    Board.find(game, piece)
    |> Enum.filter(fn %Square{} = square ->
      case {from_file, from_rank} do
        {nil, nil} -> true
        {f, nil} -> square.file == f
        {nil, r} -> square.rank == r
        {f, r} -> square.file == f and square.rank == r
      end
    end)
    |> Enum.find(fn square -> to in Square.legal_locs(square, game) end)
    |> then(fn v -> if(is_nil(v), do: nil, else: v.loc) end)
  end

  defp find_capture(%SanParser{capture: false}, _), do: nil

  defp find_capture(%SanParser{to: to}, %Game{en_passant: nil} = game),
    do: Game.get_square(game, to).piece

  defp find_capture(%SanParser{}, %Game{en_passant: _, active: :w}), do: :p
  defp find_capture(%SanParser{}, %Game{en_passant: _, active: :b}), do: :P

  def castles?(_), do: false
end
