defmodule Elchesser.Move do
  defstruct from: {},
            to: {},
            capture: false,
            promotion: false,
            castle: false

  alias __MODULE__
  alias Elchesser.{Square, Piece}

  @type t :: %__MODULE__{
          from: {number(), number()},
          to: {number(), number()},
          capture: boolean(),
          promotion: false | Piece.t(),
          castle: boolean()
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
end
