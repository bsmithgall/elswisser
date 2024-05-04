defmodule Elchesser.Game do
  defstruct board: %{},
            active: :w,
            castling: MapSet.new([:K, :Q, :k, :q]),
            en_passant: nil,
            half_clock: 0,
            full_moves: 1,
            moves: []

  alias Elchesser.{Square, Move, Board}
  alias __MODULE__

  @type t :: %Game{
          board: %{{number(), number()} => Square.t()},
          active: :w | :b,
          castling: %MapSet{},
          en_passant: Square.t() | nil,
          half_clock: number(),
          full_moves: number(),
          moves: [Square.t()]
        }

  @spec empty() :: Elchesser.Game.t()
  def empty() do
    board =
      for file <- Elchesser.files(), rank <- Elchesser.ranks(), reduce: %{} do
        acc -> Map.put(acc, {file, rank}, Square.from(file, rank))
      end

    %Game{board: board}
  end

  def get_square(%Game{board: board}, {file, rank}), do: Map.get(board, {file, rank})
  def get_square(%Game{board: board}, %Square{loc: loc}), do: Map.get(board, loc)

  @spec move(Game.t(), Move.t()) :: {:ok, Game.t()} | {:error, :atom}
  def move(%Game{} = game, %Move{} = move) do
  end

  defp ensure_valid_move(%Game{} = game, %Move{} = move) do
    with from <- Game.get_square(game, move.from),
         to <- Game.get_square(game, move.to),
         :ok <- not Square.empty?(from) |> or_(:empty_square),
         :ok <- game.active == Board.color_at(game, from) |> or_(:invalid_from_color),
         :ok <- game.active != Board.color_at(game, to) |> or_(:invalid_to_color),
         :ok <- (move.to in Square.legal_moves(game, move.from)) |> or_(:invalid_move) do
      :ok
    end
  end

  defp or_(true, _), do: :ok
  defp or_(false, reason), do: {:error, reason}
end
