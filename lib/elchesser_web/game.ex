defmodule ElchesserWeb.Game do
  use Phoenix.Component

  import ElchesserWeb.{Square, Move}

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
      <div class="border border-zinc-700 w-48 rounded-sm overflow-y-scroll">
        <table id="ec-moves" class="table-fixed w-full text-sm font-mono my-2">
          <tbody>
            <%= for {moves, idx} <- @game.moves |> Enum.chunk_every(2) |> Enum.with_index(1) |> dbg() do %>
              <.move halves={moves} number={idx} />
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end
end
