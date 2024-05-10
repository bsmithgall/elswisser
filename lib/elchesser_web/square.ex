defmodule ElchesserWeb.Square do
  use Phoenix.Component

  alias Elchesser.Square

  defguardp is_white(file, rank) when rem(file + rank, 2) != 0

  attr(:square, Square)
  attr(:square_click, :string, default: "square-click")
  attr(:highlight, :boolean, default: false)
  attr(:active, :boolean, default: false)
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
      <span class={[
        "font-mono w-full h-full inline-block text-3xl text-center align-middle cursor-pointer",
        @active && "bg-boardwhite-darker/40"
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
    <span class="w-[40px] h-[40px] mt-[4px] inline-block rounded-full border-2 border-zinc-600" />
    """
  end

  defp square_contents(%{piece: piece} = assigns) when not is_nil(piece) do
    ~H"""
    <span class={[piece_name(@piece), "w-[45px] h-[45px] mt-[1.5px] inline-block"]} />
    """
  end

  defp square_contents(assigns), do: ~H""

  defp background(%Square{file: file, rank: rank}) when is_white(file, rank), do: "bg-boardwhite"
  defp background(%Square{}), do: "bg-boardblack"

  defp piece_name(piece) do
    case piece do
      :P -> "piece-white-pawn"
      :N -> "piece-white-knight"
      :B -> "piece-white-bishop"
      :R -> "piece-white-rook"
      :Q -> "piece-white-queen"
      :K -> "piece-white-king"
      :p -> "piece-black-pawn"
      :n -> "piece-black-knight"
      :b -> "piece-black-bishop"
      :r -> "piece-black-rook"
      :q -> "piece-black-queen"
      :k -> "piece-black-king"
      nil -> ""
    end
  end
end
