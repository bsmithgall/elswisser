defmodule Elchesser.Piece do
  alias Elchesser.{Square, Game, Move}
  @type t :: :p | :n | :b | :r | :q | :k | :P | :N | :B | :R | :Q | :K

  @doc """
  Generates psuedo-legal moves for a given piece type.
  """
  @callback moves(Square.t(), Game.t()) :: [Move.t()]
  @callback attacks(Square.t(), Game.t()) :: [Move.t()]

  @white MapSet.new([:P, :N, :B, :R, :Q, :K])
  @black MapSet.new([:p, :n, :b, :r, :q, :k])

  @spec friendly?(t() | nil, t() | nil) :: boolean() | nil
  def friendly?(nil, _), do: nil
  def friendly?(_, nil), do: nil
  def friendly?(l, r), do: (white?(l) and white?(r)) or (black?(l) and black?(r))

  @spec enemy?(t() | nil, t() | nil) :: boolean()
  def enemy?(l, r), do: (white?(l) and black?(r)) or (black?(l) and white?(r))

  @spec from_string(String.t()) :: t()
  def from_string("p"), do: :p
  def from_string("n"), do: :n
  def from_string("b"), do: :b
  def from_string("r"), do: :r
  def from_string("q"), do: :q
  def from_string("k"), do: :k
  def from_string("P"), do: :P
  def from_string("N"), do: :N
  def from_string("B"), do: :B
  def from_string("R"), do: :R
  def from_string("Q"), do: :Q
  def from_string("K"), do: :K

  @spec to_string(t()) :: String.t()
  def to_string(:n), do: "N"
  def to_string(:N), do: "N"
  def to_string(:b), do: "B"
  def to_string(:B), do: "B"
  def to_string(:r), do: "R"
  def to_string(:R), do: "R"
  def to_string(:q), do: "Q"
  def to_string(:Q), do: "Q"
  def to_string(:k), do: "K"
  def to_string(:K), do: "K"

  @spec display(t() | nil) :: String.t()
  def display(nil), do: " "
  def display(:P), do: "♙"
  def display(:N), do: "♘"
  def display(:B), do: "♗"
  def display(:R), do: "♖"
  def display(:Q), do: "♕"
  def display(:K), do: "♔"
  def display(:p), do: "♟"
  def display(:n), do: "♞"
  def display(:b), do: "♝"
  def display(:r), do: "♜"
  def display(:q), do: "♛"
  def display(:k), do: "♚"

  @spec module(t()) :: module()
  def module(:r), do: Elchesser.Piece.Rook
  def module(:R), do: Elchesser.Piece.Rook
  def module(:b), do: Elchesser.Piece.Bishop
  def module(:B), do: Elchesser.Piece.Bishop
  def module(:q), do: Elchesser.Piece.Queen
  def module(:Q), do: Elchesser.Piece.Queen
  def module(:n), do: Elchesser.Piece.Knight
  def module(:N), do: Elchesser.Piece.Knight
  def module(:p), do: Elchesser.Piece.Pawn
  def module(:P), do: Elchesser.Piece.Pawn
  def module(:k), do: Elchesser.Piece.King
  def module(:K), do: Elchesser.Piece.King

  @spec int(t()) :: integer()
  @doc """
  Convert a piece to an integer so that lists of pieces can be sorted reliably
  (e.g. for displaying captures.)
  """
  def int(:P), do: 1
  def int(:N), do: 2
  def int(:B), do: 3
  def int(:R), do: 4
  def int(:Q), do: 5
  def int(:K), do: 6
  def int(:p), do: 10
  def int(:n), do: 11
  def int(:b), do: 12
  def int(:r), do: 13
  def int(:q), do: 14
  def int(:k), do: 15

  @spec white?(t()) :: boolean()
  def white?(p), do: MapSet.member?(@white, p)

  @spec black?(t()) :: boolean()
  def black?(p), do: MapSet.member?(@black, p)

  @spec color_match?(t(), :w | :b) :: boolean()
  def color_match?(p, :w), do: white?(p)
  def color_match?(p, :b), do: black?(p)

  @spec move_range(%Square{}, %Game{}, Square.Sees.t()) :: [t()]
  def move_range(%Square{} = square, %Game{} = game, direction) do
    get_in(square.sees, [Access.key!(direction)])
    |> Enum.reduce_while([], fn {file, rank}, acc ->
      s = Map.get(game.board, {file, rank})

      case friendly?(square.piece, s.piece) do
        true -> {:halt, acc}
        false -> {:halt, [Move.from(square, {s.file, s.rank}, capture: true) | acc]}
        nil -> {:cont, [Move.from(square, {s.file, s.rank}) | acc]}
      end
    end)
    |> Enum.reverse()
  end
end
