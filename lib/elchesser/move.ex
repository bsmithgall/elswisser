defmodule Elchesser.Move do
  defstruct from: {},
            to: {},
            piece: nil,
            capture: nil,
            promotion: nil,
            castle: false,
            checking: nil,
            san: nil,
            discriminator: nil

  alias __MODULE__
  alias Elchesser.{Square, Piece}

  @type t :: %__MODULE__{
          from: {number(), number()},
          to: {number(), number()},
          piece: Piece.t(),
          capture: Piece.t?(),
          promotion: Piece.t?(),
          castle: boolean(),
          checking: nil | :check | :checkmate | :stalemate,
          san: nil | binary(),
          discriminator: nil | :file | :rank | :both
        }

  def from({file, rank}), do: %Move{to: {file, rank}}
  def from({f1, r1, p}, {f2, r2}), do: %Move{from: {f1, r1}, to: {f2, r2}, piece: p}

  def from(from, to, opts \\ [])

  @spec from(Elchesser.Square.t() | {number(), number(), Piece.t()}, {number(), number()}, list()) ::
          t()
  def from({f1, r1, piece}, {f2, r2}, opts) do
    opts = validate_opts(opts)
    Map.merge(%Move{from: {f1, r1}, to: {f2, r2}, piece: piece}, opts |> Enum.into(%{}))
  end

  def from(%Square{} = from, to, opts) do
    opts = validate_opts(opts)

    Map.merge(
      %Move{from: {from.file, from.rank}, to: to, piece: from.piece},
      opts |> Enum.into(%{})
    )
  end

  @spec san(Move.t()) :: binary()
  def san(%Move{checking: nil} = move), do: as_san(move)
  def san(%Move{checking: :check} = move), do: as_san(move) <> "+"
  def san(%Move{checking: :checkmate} = move), do: as_san(move) <> "#"
  def san(%Move{checking: :stalemate} = move), do: as_san(move) <> "="

  @spec as_san(Move.t()) :: binary()
  defp as_san(%Move{castle: true, to: {?g, _}, piece: piece}) when piece in [:k, :K], do: "O-O"
  defp as_san(%Move{castle: true, to: {?c, _}, piece: piece}) when piece in [:k, :K], do: "O-O-O"

  defp as_san(%Move{capture: nil, promotion: nil, to: {f, r}, piece: piece})
       when piece in [:p, :P] do
    <<f, r + 48>>
  end

  defp as_san(%Move{capture: c, promotion: nil, from: {f, _}, to: {f2, r}, piece: piece})
       when piece in [:p, :P] and not is_nil(c) do
    <<f>> <> "x" <> <<f2, r + 48>>
  end

  defp as_san(%Move{capture: nil, promotion: prom, to: {f, r}, piece: piece})
       when prom != false and piece in [:p, :P] do
    <<f, r + 48>> <> "=" <> Piece.to_string(prom)
  end

  defp as_san(%Move{capture: c, promotion: prom, from: {f, _}, to: {f2, r}, piece: piece})
       when prom != false and piece in [:p, :P] and not is_nil(c) do
    <<f>> <> "x" <> <<f2, r + 48>> <> "=" <> Piece.to_string(prom)
  end

  defp as_san(%Move{capture: nil, to: {f, r}, piece: piece} = move) do
    Piece.to_string(piece) <> discriminator(move) <> <<f, r + 48>>
  end

  defp as_san(%Move{capture: c, to: {f, r}, piece: piece} = move) when not is_nil(c) do
    Piece.to_string(piece) <> discriminator(move) <> "x" <> <<f, r + 48>>
  end

  defp validate_opts(opts) do
    {_, opts} =
      Keyword.validate(opts,
        capture: nil,
        promotion: nil,
        castle: false,
        checking: nil,
        discriminator: nil
      )

    opts
  end

  defp discriminator(%Move{discriminator: nil}), do: ""
  defp discriminator(%Move{discriminator: :file, from: {f, _}}), do: <<f>>
  defp discriminator(%Move{discriminator: :rank, from: {_, r}}), do: <<r + 48>>
  defp discriminator(%Move{discriminator: :both, from: {f, r}}), do: <<f, r + 48>>
end
