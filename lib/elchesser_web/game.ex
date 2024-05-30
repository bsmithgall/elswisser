defmodule ElchesserWeb.Game do
  use Phoenix.Component

  import ElchesserWeb.{Board, Moves}

  attr(:target, :string)
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
          target={@target}
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
          target={@target}
        />
      </div>
      <div class="border border-zinc-700 w-[324px] sm:w-[388px] md:w-48 rounded-sm flex flex-col max-h-[388px]">
        <.captures pieces={if @orientation == :w, do: @white_captures, else: @black_captures} />
        <.moves moves={@moves} class="grow" active_move={@active_move - 1} target={@target} />
        <.captures pieces={if @orientation == :w, do: @black_captures, else: @white_captures} />
      </div>
    </div>
    """
  end
end
