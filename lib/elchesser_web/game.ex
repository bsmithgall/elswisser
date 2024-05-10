defmodule ElchesserWeb.Game do
  use Phoenix.Component

  import ElchesserWeb.Square

  alias Elchesser.Game

  attr(:game, Game)
  attr(:active, Elchesser.Square, default: nil)
  attr(:move_map, :map, default: %{})
  attr(:square_click, :string, default: "square-click")
  attr(:next_click, :string, values: ["start", "stop"])

  def game(assigns) do
    ~H"""
    <div class="relative m-auto left-0 right-0">
      <div class="absolute left-1/2 -translate-x-1/2 border border-2 border-zinc-700">
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
    </div>
    """
  end
end
