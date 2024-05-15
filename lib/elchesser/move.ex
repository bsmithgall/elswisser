defmodule Elchesser.Move do
  defstruct from: {},
            to: {},
            capture: false,
            promotion: false,
            castle: false,
            san: ""

  alias __MODULE__
  alias Elchesser.{Square, Piece}

  @type t :: %__MODULE__{
          from: {number(), number()},
          to: {number(), number()},
          capture: boolean(),
          promotion: false | Piece.t(),
          castle: boolean(),
          san: binary()
        }

  def from({file, rank}), do: %Move{to: {file, rank}}
  def from({f1, r1}, {f2, r2}), do: %Move{from: {f1, r1}, to: {f2, r2}}

  def from(from, to, opts \\ [])

  @spec from(Elchesser.Square.t() | {number(), number()}, {number(), number()}, list()) :: t()
  def from({f1, r1}, {f2, r2}, opts) do
    {_, opts} = Keyword.validate(opts, capture: false, promotion: false, castle: false)

    Map.merge(%Move{from: {f1, r1}, to: {f2, r2}}, opts |> Enum.into(%{}))
  end

  def from(%Square{} = from, to, opts) do
    {_, opts} = Keyword.validate(opts, capture: false, promotion: false, castle: false)

    Map.merge(
      %Move{from: {from.file, from.rank}, to: to},
      opts |> Enum.into(%{})
    )
  end

  @spec as_san(Move.t(), Piece.t()) :: binary()
  def as_san(%Move{castle: true, to: {?g, _}}, piece) when piece in [:k, :K], do: "O-O"
  def as_san(%Move{castle: true, to: {?c, _}}, piece) when piece in [:k, :K], do: "O-O-O"

  def as_san(%Move{capture: false, promotion: false, to: {f, r}}, piece)
      when piece in [:p, :P] do
    <<f, r + 48>>
  end

  def as_san(%Move{capture: true, promotion: false, from: {f, _}, to: {f2, r}}, piece)
      when piece in [:p, :P] do
    <<f>> <> "x" <> <<f2, r + 48>>
  end

  def as_san(%Move{capture: false, promotion: prom, to: {f, r}}, piece)
      when prom != false and piece in [:p, :P] do
    <<f, r + 48>> <> "=" <> Piece.to_string(prom)
  end

  def as_san(%Move{capture: true, promotion: prom, from: {f, _}, to: {f2, r}}, piece)
      when prom != false and piece in [:p, :P] do
    <<f>> <> "x" <> <<f2, r + 48>> <> "=" <> Piece.to_string(prom)
  end

  def as_san(%Move{capture: false, to: {f, r}}, piece) do
    Piece.to_string(piece) <> <<f, r + 48>>
  end

  def as_san(%Move{capture: true, to: {f, r}}, piece) do
    Piece.to_string(piece) <> "x" <> <<f, r + 48>>
  end

  @spec as_san(Move.t(), Piece.t(), :check | :checkmate | :stalemate) :: binary()
  def as_san(move, piece, :check), do: as_san(move, piece) <> "+"
  def as_san(move, piece, :checkmate), do: as_san(move, piece) <> "#"
  def as_san(move, piece, :stalemate), do: as_san(move, piece) <> "="

  @spec with_san(Move.t(), Piece.t()) :: Move.t()
  def with_san(move, piece), do: %Move{move | san: as_san(move, piece)}

  @spec with_san(Move.t(), Piece.t(), :check | :checkmate | :stalemate) :: Move.t()
  def with_san(move, piece, checking), do: %Move{move | san: as_san(move, piece, checking)}
end
