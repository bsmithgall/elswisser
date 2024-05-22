defmodule ElchesserWeb.Game do
  use Phoenix.Component

  import ElchesserWeb.{Square, Piece}

  alias Elchesser.Game

  attr(:game, Game)
  attr(:moves, :list)
  attr(:active_square, Elchesser.Square, default: nil)
  attr(:active_move, :integer, default: 0)
  attr(:move_map, :map, default: %{})
  attr(:square_click, :string, default: "square-click")
  attr(:next_click, :string, values: ["start", "stop"])

  def game(assigns) do
    ~H"""
    <div
      phx-hook="ElchesserHook"
      id="ec-game"
      class="relative m-auto left-0 right-0 flex flex-col md:flex-row md:justify-center gap-4"
    >
      <.board
        game={@game}
        move_map={@move_map}
        active_square={@active_square}
        next_click={@next_click}
      />
      <div class="border border-zinc-700 w-[324px] sm:w-[388px] md:w-48 rounded-sm flex flex-col">
        <.captures pieces={Game.captures(@game, :w)} />
        <.moves
          moves={@moves}
          class="grow"
          active_move={:erlang.div(@active_move, 2)}
          active_color={:erlang.rem(@active_move, 2)}
        />
        <.captures pieces={Game.captures(@game, :b)} />
      </div>
    </div>
    """
  end

  attr(:game, Game)
  attr(:active_square, Elchesser.Square, default: nil)
  attr(:move_map, :map, default: %{})
  attr(:next_click, :string, values: ["start", "stop"])

  def board(assigns) do
    ~H"""
    <div class="border border-2 border-zinc-700 grid grid-rows-8 grid-cols-8 h-[324px] sm:h-[388px] w-[324px] sm:w-[388px]">
      <%= for rank <- Elchesser.ranks() |> Enum.reverse() do %>
        <%= for file <- Elchesser.files() do %>
          <.square
            square={Game.get_square(@game, {file, rank})}
            highlight={Map.has_key?(@move_map, {file, rank})}
            click_type={@next_click}
            active={not is_nil(@active_square) && @active_square.loc == {file, rank}}
          />
        <% end %>
      <% end %>
    </div>
    """
  end

  attr(:class, :string, default: nil)
  attr(:moves, :list, default: [])
  attr(:active_move, :integer, default: nil)
  attr(:active_color, :integer, values: [0, 1])

  def moves(assigns) do
    ~H"""
    <div class={["border-y border-zinc-400 bg-zinc-50 min-h-24", @class]}>
      <table id="ec-moves" class="overflow-y-scroll table-fixed w-full text-sm font-mono my-2">
        <tbody>
          <%= for {moves, number} <- @moves |> Enum.chunk_every(2) |> Enum.with_index(1) do %>
            <tr>
              <td class="w-8"><%= number %>.</td>
              <%= for {move, color} <- moves |> Enum.with_index() do %>
                <td
                  class={[
                    "cursor-pointer hover:bg-zinc-300",
                    number == @active_move && color == @active_color &&
                      "bg-zinc-300"
                  ]}
                  phx-click="view-game-at"
                  phx-value-number={number}
                  phx-value-color={color}
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
    <div class="min-h-10 flex flex-wrap m-1">
      <%= for piece <- @pieces do %>
        <.piece piece={piece} class="w-4 h-4 b-0.5 text-center" />
      <% end %>
    </div>
    """
  end
end
