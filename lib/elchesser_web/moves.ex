defmodule ElchesserWeb.Moves do
  use Phoenix.Component

  import ElchesserWeb.Piece

  attr(:class, :string, default: nil)
  attr(:moves, :list, default: [])
  attr(:active_move, :integer, default: nil)
  attr(:target, :string)

  def moves(assigns) do
    ~H"""
    <div
      id="ec-moves"
      class={[
        "border-y border-zinc-400 bg-zinc-50 min-h-24 max-h-[290px] overflow-y-scroll",
        @class
      ]}
    >
      <table class="table-fixed w-full text-sm font-mono my-2">
        <tbody>
          <%= for {moves, number} <- @moves |> Enum.with_index() |> Enum.chunk_every(2) |> Enum.with_index(1) do %>
            <tr>
              <td class="w-8"><%= number %>.</td>
              <%= for {move, idx} <- moves do %>
                <td
                  class={[
                    "cursor-pointer hover:bg-zinc-300",
                    idx == @active_move && "bg-zinc-300"
                  ]}
                  data-active-move={@active_move == idx}
                  phx-click="view-game-at"
                  phx-value-idx={idx}
                  phx-target={@target}
                >
                  <span class="m-1"><%= move.san %></span>
                </td>
              <% end %>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  attr(:pieces, :list, default: [])

  def captures(assigns) do
    ~H"""
    <div class="h-10 flex flex-wrap m-1">
      <%= for piece <- @pieces do %>
        <.piece piece={piece} class="w-4 h-4 b-0.5 text-center" />
      <% end %>
    </div>
    """
  end
end
