defmodule ElchesserWeb.Square do
  use Phoenix.Component

  alias Elchesser.{Square, Piece}

  defguardp is_white(file, rank) when rem(file + rank, 2) != 0

  attr(:square, Square)
  attr(:square_click, :string, default: "square-click")
  attr(:highlight, :boolean, default: false)
  attr(:active, :boolean, default: false)
  attr(:click_type, :atom, values: [:start, :stop])

  def square(assigns) do
    ~H"""
    <div
      id={Square.rf_string(@square)}
      class={["w-10 h-10 sm:w-12 sm:h-12", background(@square)]}
      phx-click={@square_click}
      phx-value-file={@square.file}
      phx-value-rank={@square.rank}
      phx-value-type={@click_type}
      data-square
      data-file={@square.file}
      data-rank={@square.rank}
    >
      <span class={[
        "font-mono w-full h-full inline-block text-3xl text-center align-middle cursor-pointer ",
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
    <span class="w-[38px] md:w-[45px] h-[38px] md:h-[45px] mt-[1px] md:mt-[1.5px] inline-block rounded-full border-2 border-zinc-600" />
    """
  end

  defp square_contents(%{piece: piece, highlight: true} = assigns) when not is_nil(piece) do
    ~H"""
    <div class="relative">
      <span class="absolute w-[38px] sm:w-[45px] h-[38px] sm:h-[45px] mt-[1px] sm:mt-[1.5px] inline-block rounded-full border-2 border-zinc-600" />
      <.piece piece={@piece} class="w-[38px] sm:w-[45px] h-[38px] sm:h-[45px] mt-[1px] sm:mt-[1.5px]" />
    </div>
    """
  end

  defp square_contents(%{piece: piece, highlight: false} = assigns) when not is_nil(piece) do
    ~H"""
    <.piece piece={@piece} class="w-[38px] md:w-[45px] h-[38px] md:h-[45px] mt-[1px] md:mt-[1.5px]" />
    """
  end

  defp square_contents(assigns), do: ~H""

  attr(:piece, :atom)
  attr(:class, :string, default: nil)
  attr(:draggable, :boolean, default: true)

  def piece(assigns) do
    ~H"""
    <span
      data-color={Piece.color(@piece)}
      draggable={"#{@draggable}"}
      class={[piece_name(@piece), @class]}
    />
    """
  end

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

  defp background(%Square{file: file, rank: rank}) when is_white(file, rank), do: "bg-boardwhite"
  defp background(%Square{}), do: "bg-boardblack"
end
