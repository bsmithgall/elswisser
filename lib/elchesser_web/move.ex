defmodule ElchesserWeb.Move do
  use Phoenix.Component

  attr(:number, :integer)
  attr(:halves, :list, default: [])

  def move(assigns) do
    ~H"""
    <tr class="even:bg-zinc-100">
      <td class="w-8"><%= @number %>.</td>
      <%= for m <- @halves do %>
        <td><%= m.san %></td>
      <% end %>
    </tr>
    """
  end
end
