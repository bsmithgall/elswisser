defmodule ElchesserWeb.Game do
  use Phoenix.Component

  import ElchesserWeb.Square
  import ElswisserWeb.CoreComponents

  alias Elchesser.Game

  attr(:board, :map)
  attr(:moves, :list)
  attr(:white_captures, :list)
  attr(:black_captures, :list)
  attr(:active_color, :atom)
  attr(:active_square, Elchesser.Square, default: nil)
  attr(:active_move, :integer, default: 0)
  attr(:move_map, :map, default: %{})
  attr(:square_click, :string, default: "square-click")
  attr(:next_click, :string, values: ["start", "stop"])
  attr(:orientation, :atom, values: [:w, :b], default: :w)

  def game(assigns) do
    ~H"""
    <div
      phx-hook="ElchesserHook"
      id="ec-game"
      class="relative m-auto left-0 right-0 flex flex-col md:flex-row md:justify-center gap-4"
      data-active-color={@active_color}
    >
      <div class="w-[324px] sm:w-[388px]">
        <.board
          board={@board}
          move_map={@move_map}
          active_square={@active_square}
          next_click={@next_click}
          orientation={@orientation}
        />
        <.board_controls
          active_move={@active_move - 1}
          total_moves={length(@moves)}
          orientation={@orientation}
        />
      </div>
      <div class="border border-zinc-700 w-[324px] sm:w-[388px] md:w-48 rounded-sm flex flex-col max-h-[388px]">
        <.captures pieces={if @orientation == :w, do: @white_captures, else: @black_captures} />
        <.moves moves={@moves} class="grow" active_move={@active_move - 1} />
        <.captures pieces={if @orientation == :w, do: @black_captures, else: @white_captures} />
      </div>
    </div>
    """
  end

  attr(:board, :map)
  attr(:active_square, Elchesser.Square, default: nil)
  attr(:move_map, :map, default: %{})
  attr(:next_click, :string, values: ["start", "stop"])
  attr(:orientation, :atom, values: [:w, :b])

  def board(assigns) do
    assigns =
      assigns
      |> assign(
        ranks:
          if(assigns.orientation == :w,
            do: Elchesser.ranks() |> Enum.reverse(),
            else: Elchesser.ranks()
          )
      )
      |> assign(
        files:
          if(assigns.orientation == :w,
            do: Elchesser.files(),
            else: Elchesser.files() |> Enum.reverse()
          )
      )

    ~H"""
    <div
      id="board"
      class="border border-2 border-zinc-700 grid grid-rows-8 grid-cols-8 h-[324px] sm:h-[388px]  select-none"
    >
      <%= for rank <- @ranks do %>
        <%= for file <- @files do %>
          <.square
            square={Game.get_square(@board, {file, rank})}
            highlight={Map.has_key?(@move_map, {file, rank})}
            click_type={@next_click}
            active={not is_nil(@active_square) && @active_square.loc == {file, rank}}
          />
        <% end %>
      <% end %>
    </div>
    """
  end

  attr(:active_move, :integer)
  attr(:total_moves, :integer)
  attr(:orientation, :atom, values: [:w, :b])

  def board_controls(assigns) do
    ~H"""
    <div class="pt-2 flex place-content-center text-center items-center">
      <.icon_button large name="hero-chevron-double-left" phx-click="view-game-at" phx-value-idx={0} />
      <.icon_button
        large
        name="hero-arrow-left"
        phx-click="view-game-at"
        phx-value-idx={@active_move - 1}
      />
      <.icon_button
        large
        name="hero-arrow-right"
        phx-click="view-game-at"
        phx-value-idx={@active_move + 1}
      />
      <.icon_button
        large
        name="hero-chevron-double-right"
        phx-click="view-game-at"
        phx-value-idx={@total_moves - 1}
      />
      <.icon_button
        large
        name="hero-arrows-up-down"
        phx-click="flip-board"
        phx-value-current={@orientation}
      />
    </div>
    """
  end

  attr(:class, :string, default: nil)
  attr(:moves, :list, default: [])
  attr(:active_move, :integer, default: nil)

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
                  phx-click="view-game-at"
                  phx-value-idx={idx}
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
