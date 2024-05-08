defmodule ElchesserWeb.Game do
  use Phoenix.Component

  alias Elchesser.{Game}

  import ElchesserWeb.Square

  attr(:game, Game)
  attr(:move_map, :map, default: %{})
  attr(:square_click, :string, default: "square-click")
  attr(:next_click, :string, values: ["start", "stop"])

  def game(assigns) do
    ~H"""
    <div class="relative">
      <div class="absolute border border-2 border-zinc-700">
        <%= for rank <- Elchesser.ranks() |> Enum.reverse() do %>
          <div class="flex">
            <%= for file <- Elchesser.files() do %>
              <.square
                square={Game.get_square(@game, {file, rank})}
                highlight={Map.has_key?(@move_map, {file, rank})}
                click_type={@next_click}
              />
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
