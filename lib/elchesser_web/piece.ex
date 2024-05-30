defmodule ElchesserWeb.Piece do
  use Phoenix.Component

  alias Elchesser.Piece

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
end
