defmodule ElchesserWeb.Square do
  use Phoenix.Component

  alias Elchesser.Square

  import ElchesserWeb.Piece

  defguardp is_white(file, rank) when rem(file + rank, 2) != 0

  attr(:square, Square)
  attr(:square_click, :string, default: "square-click")
  attr(:highlight, :boolean, default: false)
  attr(:active, :boolean, default: false)
  attr(:click_type, :atom, values: [:start, :stop])

  def square(assigns) do
    ~H"""
    <div
      class={["w-10 h-10 md:w-12 md:h-12", background(@square)]}
      phx-click={@square_click}
      phx-value-file={@square.file}
      phx-value-rank={@square.rank}
      phx-value-type={@click_type}
    >
      <span class={[
        "font-mono w-full h-full inline-block text-3xl text-center align-middle cursor-pointer",
        @active && "bg-purple-200/60"
      ]}>
        <.square_contents highlight={@highlight} piece={@square.piece} />
      </span>
    </div>
    """
  end

  attr(:piece, :atom, default: nil)
  attr(:highlight, :boolean, default: false)

  defp square_contents(%{piece: nil, highlight: true} = assigns) do
    ~H"""
    <span class="md:w-[45px] md:h-[45px] md:mt-[1.5px] inline-block rounded-full border-2 border-zinc-600" />
    """
  end

  defp square_contents(%{piece: piece, highlight: true} = assigns) when not is_nil(piece) do
    ~H"""
    <div class="relative">
      <span class="absolute md:w-[45px] md:h-[45px] md:mt-[1.5px] inline-block rounded-full border-2 border-zinc-600" />
      <.piece piece={@piece} class="w-[45px] h-[45px] mt-[1.5px]" />
    </div>
    """
  end

  defp square_contents(%{piece: piece, highlight: false} = assigns) when not is_nil(piece) do
    ~H"""
    <.piece piece={@piece} class="md:w-[45px] md:h-[45px] md:mt-[1.5px]" />
    """
  end

  defp square_contents(assigns), do: ~H""

  defp background(%Square{file: file, rank: rank}) when is_white(file, rank), do: "bg-boardwhite"
  defp background(%Square{}), do: "bg-boardblack"
end
