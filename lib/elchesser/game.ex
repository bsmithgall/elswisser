defmodule Elchesser.Game do
  require IEx
  alias Elchesser.{Square, Move, Board, Piece}
  alias __MODULE__

  @starting_position "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

  defstruct board: %{},
            active: :w,
            check: false,
            castling: MapSet.new([:K, :Q, :k, :q]),
            en_passant: nil,
            half_moves: 0,
            full_moves: 1,
            moves: [],
            captures: []

  @type t :: %Game{
          board: %{{number(), number()} => Square.t()},
          active: :w | :b,
          check: boolean(),
          castling: %MapSet{},
          en_passant: {number(), number()} | nil,
          half_moves: number(),
          full_moves: number(),
          moves: [Move.t()],
          captures: [Piece.t()]
        }

  @spec empty() :: Elchesser.Game.t()
  def empty() do
    board =
      for file <- Elchesser.files(), rank <- Elchesser.ranks(), reduce: %{} do
        acc -> Map.put(acc, {file, rank}, Square.from(file, rank))
      end

    %Game{board: board}
  end

  def new() do
    Elchesser.Fen.parse(@starting_position)
  end

  def get_square(%Game{board: board}, {file, rank}), do: Map.get(board, {file, rank})
  def get_square(%Game{board: board}, %Square{loc: loc}), do: Map.get(board, loc)

  @spec move(Game.t(), Move.t()) :: {:error, atom()} | {:ok, Game.t()}
  def move(%Game{} = game, %Move{} = move) do
    with :ok <- ensure_valid_move(game, move),
         {:ok, {move, game}} <- Board.move(game, move) do
      game =
        game
        |> flip_color()
        |> set_in_check()
        |> add_move(move)
        |> add_capture(move.capture)
        |> set_castling_rights(move)
        |> set_en_passant(move)
        |> set_half_move_count(move)
        |> set_full_move_count()

      {:ok, game}
    end
  end

  def move(_, nil), do: {:error, :no_move_provided}

  @spec move!(Game.t(), Move.t()) :: Game.t()
  def move!(%Game{} = game, %Move{} = move) do
    {:ok, game} = move(game, move)
    game
  end

  def captures(%Game{} = game, :w) do
    game.captures
    |> Enum.filter(fn p ->
      s = Atom.to_string(p)
      s == String.upcase(s)
    end)
  end

  def captures(%Game{} = game, :b) do
    game.captures
    |> Enum.filter(fn p ->
      s = Atom.to_string(p)
      s != String.upcase(s)
    end)
  end

  defp ensure_valid_move(%Game{} = game, %Move{} = move) do
    with from <- Game.get_square(game, move.from),
         to <- Game.get_square(game, move.to),
         :ok <- not Square.empty?(from) |> or_(:empty_square),
         :ok <- (game.active == Board.color_at(game, from)) |> or_(:invalid_from_color),
         :ok <- (game.active != Board.color_at(game, to)) |> or_(:invalid_to_color),
         :ok <- (move.to in Square.legal_locs(from, game)) |> or_(:invalid_move) do
      :ok
    end
  end

  defp add_move(%Game{moves: moves} = game, %Move{} = move) do
    %Game{game | moves: Enum.concat(moves, [move])}
  end

  @spec add_capture(Game.t(), Piece.t?()) :: Game.t()
  defp add_capture(game, nil), do: game

  defp add_capture(%Game{captures: captures} = game, piece) do
    captures = [piece | captures] |> Enum.sort_by(&Piece.int/1)
    %Game{game | captures: captures}
  end

  defp flip_color(%Game{active: :w} = game), do: %Game{game | active: :b}
  defp flip_color(%Game{active: :b} = game), do: %Game{game | active: :w}

  @spec set_in_check(Game.t()) :: Game.t()
  defp set_in_check(%Game{} = game), do: %Game{game | check: Game.Check.check?(game, game.active)}

  @spec set_castling_rights(Game.t(), Move.t()) :: Game.t()
  defp set_castling_rights(%Game{castling: castling} = game, %Move{piece: :K}) do
    %Game{game | castling: MapSet.delete(castling, :K) |> MapSet.delete(:Q)}
  end

  defp set_castling_rights(%Game{castling: castling} = game, %Move{piece: :k}) do
    %Game{game | castling: MapSet.delete(castling, :k) |> MapSet.delete(:q)}
  end

  defp set_castling_rights(%Game{castling: castling} = game, %Move{from: {?h, 1}, piece: :R}) do
    %Game{game | castling: MapSet.delete(castling, :K)}
  end

  defp set_castling_rights(%Game{castling: castling} = game, %Move{from: {?a, 1}, piece: :R}) do
    %Game{game | castling: MapSet.delete(castling, :Q)}
  end

  defp set_castling_rights(%Game{castling: castling} = game, %Move{from: {?h, 8}, piece: :r}) do
    %Game{game | castling: MapSet.delete(castling, :k)}
  end

  defp set_castling_rights(%Game{castling: castling} = game, %Move{from: {?a, 8}, piece: :r}) do
    %Game{game | castling: MapSet.delete(castling, :q)}
  end

  defp set_castling_rights(game, _), do: game

  @spec set_en_passant(Game.t(), Move.t()) :: Game.t()
  defp set_en_passant(%Game{} = game, %Move{from: {f, 2}, to: {f, 4}, piece: :P}),
    do: %Game{game | en_passant: {f, 3}}

  defp set_en_passant(%Game{} = game, %Move{from: {f, 7}, to: {f, 5}, piece: :p}),
    do: %Game{game | en_passant: {f, 6}}

  defp set_en_passant(%Game{} = game, _), do: %Game{game | en_passant: nil}

  @spec set_half_move_count(Game.t(), Move.t()) :: Game.t()
  defp set_half_move_count(game, %Move{piece: piece}) when piece in [:P, :p] do
    %Game{game | half_moves: 0}
  end

  defp set_half_move_count(game, %Move{capture: capture}) when not is_nil(capture) do
    %Game{game | half_moves: 0}
  end

  defp set_half_move_count(%Game{half_moves: half_moves} = game, _) do
    %Game{game | half_moves: half_moves + 1}
  end

  defp set_full_move_count(%Game{active: :w, full_moves: full_moves} = game),
    do: %Game{game | full_moves: full_moves + 1}

  defp set_full_move_count(game), do: game

  @spec or_(boolean(), atom()) :: :ok | {:error, atom()}
  defp or_(true, _), do: :ok
  defp or_(false, reason), do: {:error, reason}
end
