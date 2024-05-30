defmodule ElchesserWeb.Board do
  use Phoenix.Component

  alias Elchesser.Game

  import ElchesserWeb.Square
  import ElswisserWeb.CoreComponents, only: [icon_button: 1]

  attr(:board, :map)
  attr(:active_square, Elchesser.Square, default: nil)
  attr(:move_map, :map, default: %{})
  attr(:next_click, :string, values: ["start", "stop"])
  attr(:orientation, :atom, values: [:w, :b])
  attr(:target, :string)
  attr(:files, :list, default: nil)
  attr(:ranks, :list, default: nil)

  def board(%{orientation: :w, ranks: nil, files: nil} = assigns) do
    assigns
    |> assign(ranks: Enum.reverse(Elchesser.ranks()))
    |> assign(files: Elchesser.files())
    |> board()
  end

  def board(%{orientation: :b, ranks: nil, files: nil} = assigns) do
    assigns
    |> assign(ranks: Elchesser.ranks())
    |> assign(files: Elchesser.files() |> Enum.reverse())
    |> board()
  end

  def board(%{ranks: r, files: f} = assigns) when not is_nil(r) and not is_nil(f) do
    ~H"""
    <div
      id="board"
      class="border border-2 border-zinc-700 grid grid-rows-8 grid-cols-8 h-[324px] sm:h-[388px]  select-none"
    >
      <%= for rank <- @ranks do %>
        <%= for file <- @files do %>
          <.square
            target={@target}
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
  attr(:target, :string)

  def board_controls(assigns) do
    ~H"""
    <div class="pt-2 flex place-content-center text-center items-center">
      <.icon_button
        large
        name="hero-chevron-double-left"
        disabled={@total_moves == 0}
        phx-click="view-game-at"
        phx-value-idx={0}
        phx-target={@target}
      />
      <.icon_button
        large
        name="hero-arrow-left"
        disabled={@total_moves == 0}
        phx-click="view-game-at"
        phx-value-idx={@active_move - 1}
        phx-target={@target}
      />
      <.icon_button
        large
        name="hero-arrow-right"
        disabled={@total_moves == 0}
        phx-click="view-game-at"
        phx-value-idx={@active_move + 1}
        phx-target={@target}
      />
      <.icon_button
        large
        name="hero-chevron-double-right"
        disabled={@total_moves == 0}
        phx-click="view-game-at"
        phx-value-idx={@total_moves - 1}
        phx-target={@target}
      />
      <.icon_button
        large
        name="hero-arrows-up-down"
        phx-click="flip-board"
        phx-value-current={@orientation}
        phx-target={@target}
      />
    </div>
    """
  end
end
