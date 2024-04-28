defmodule Elchesser.Piece do
  @white MapSet.new([:P, :N, :B, :R, :Q, :K])
  @black MapSet.new([:p, :n, :b, :r, :q, :k])

  @type t :: :p | :n | :b | :r | :q | :k | :P | :N | :B | :R | :Q | :K

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

  @spec display(Elchesser.piece() | nil) :: String.t()
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

  defp white?(p), do: MapSet.member?(@white, p)
  defp black?(p), do: MapSet.member?(@black, p)
end
