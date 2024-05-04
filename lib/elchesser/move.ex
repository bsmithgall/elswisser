defmodule Elchesser.Move do
  defstruct from: {},
            to: {},
            capture: false,
            promotion: false,
            castle: false

  alias __MODULE__
  alias Elchesser.Square

  @type t :: %__MODULE__{}

  def from({file, rank}), do: %Move{to: {file, rank}}
  def from({f1, r1}, {f2, r2}), do: %Move{from: {f1, r1}, to: {f2, r2}}

  @spec from(Elchesser.Square.t(), {number(), number()}, list()) :: t()
  def from(%Square{} = from, to, opts \\ []) do
    {_, opts} = Keyword.validate(opts, capture: false, promotion: false, castle: false)

    Map.merge(
      %Move{from: {from.file, from.rank}, to: to},
      opts |> Enum.into(%{})
    )
  end
end
