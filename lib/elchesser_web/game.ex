defmodule ElchesserWeb.Game do
  use Phoenix.Component

  import ElchesserWeb.{Square, Piece}

  alias Elchesser.Game

  attr(:game, Game)
  attr(:active, Elchesser.Square, default: nil)
  attr(:move_map, :map, default: %{})
  attr(:square_click, :string, default: "square-click")
  attr(:next_click, :string, values: ["start", "stop"])

  def game(assigns) do
    ~H"""
    <div
      phx-hook="ElchesserHook"
      id="ec-game"
      class="relative m-auto left-0 right-0 flex justify-center gap-x-4 max-h-[388px]"
    >
      <div class="border border-2 border-zinc-700">
        <%= for rank <- Elchesser.ranks() |> Enum.reverse() do %>
          <div class="flex">
            <%= for file <- Elchesser.files() do %>
              <.square
                square={Game.get_square(@game, {file, rank})}
                highlight={Map.has_key?(@move_map, {file, rank})}
                click_type={@next_click}
                active={not is_nil(@active) && @active.loc == {file, rank}}
              />
            <% end %>
          </div>
        <% end %>
      </div>
      <div class="border border-zinc-700 w-48 rounded-sm flex flex-col">
        <.captures pieces={Game.captures(@game, :w)} />
        <.moves moves={@game.moves} class="grow" />
        <.captures pieces={Game.captures(@game, :b)} />
      </div>
    </div>
    """
  end

  attr(:class, :string, default: nil)
  attr(:moves, :list, default: [])

  def moves(assigns) do
    ~H"""
    <div class={["border-y border-zinc-400 bg-zinc-50", @class]}>
      <table id="ec-moves" class="overflow-y-scroll table-fixed w-full text-sm font-mono my-2">
        <tbody>
          <%= for {moves, number} <- @moves |> Enum.chunk_every(2) |> Enum.with_index(1) do %>
            <tr class="even:bg-zinc-100">
              <td class="w-8"><%= number %>.</td>
              <%= for move <- moves do %>
                <td><%= move.san %></td>
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
    <div class="min-h-10 flex flex-wrap m-1">
      <%= for piece <- @pieces do %>
        <.piece piece={piece} class="w-4 h-4 b-0.5 text-center" />
      <% end %>
    </div>
    """
  end
end
