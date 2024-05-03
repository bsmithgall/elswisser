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

  @spec from(Elchesser.Square.t(), {number(), number()}) :: t()
  def from(%Square{} = from, to, opts \\ []) do
    {_, opts} = Keyword.validate(opts, capture: false, promotion: false, castle: false)

    Map.merge(
      %Move{from: {from.file, from.rank}, to: to},
      opts |> Enum.into(%{})
    )
  end
end
