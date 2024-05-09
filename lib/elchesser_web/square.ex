defmodule ElchesserWeb.Square do
  use Phoenix.Component

  alias Elchesser.{Square, Piece}

  defguardp is_white(file, rank) when rem(file + rank, 2) == 0

  attr(:square, Square)
  attr(:square_click, :string, default: "square-click")
  attr(:highlight, :boolean, default: false)
  attr(:click_type, :atom, values: [:start, :stop])

  def square(assigns) do
    ~H"""
    <div
      class={["w-12 h-12", background(@square)]}
      phx-click={@square_click}
      phx-value-file={@square.file}
      phx-value-rank={@square.rank}
      phx-value-type={@click_type}
    >
      <span class="font-mono w-full h-full inline-block text-3xl text-center align-middle cursor-pointer">
        <%= Piece.display(@square.piece) %>
        <span :if={@highlight}>hi</span>
      </span>
    </div>
    """
  end

  defp background(%Square{file: file, rank: rank}) when is_white(file, rank), do: "bg-boardwhite"
  defp background(%Square{}), do: "bg-boardblack"
end
