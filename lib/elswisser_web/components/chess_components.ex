defmodule ElswisserWeb.ChessComponents do
  @moduledoc """
  Similar to core_components, this is meant to provide shared components for
  representations of different things across the application. Of course, the
  application is wildly different because I am just hacking this together as I
  go, but what can you do.
  """

  use Phoenix.Component
  use Phoenix.VerifiedRoutes, endpoint: ElswisserWeb.Endpoint, router: ElswisserWeb.Router

  attr(:game, :map, required: true)
  attr(:highlight, :atom, values: [:white, :black])
  attr(:class, :string, default: nil)

  def game_result(assigns) do
    ~H"""
    <div class={["grid grid-cols-3 grid-rows-2 gap-x-4 min-w-min", @class && @class]}>
      <span class="col-span-2">
        <.white_square winner={@game.result == 1} />
        <.link class="hover:underline" href={~p"/players/#{@game.white.id}"}>
          <%= @game.white.name %>
        </.link>
      </span>
      <span><.score color={:white} result={@game.result} /></span>
      <span class="col-span-2">
        <.black_square winner={@game.result == -1} />
        <.link class="hover:underline" href={~p"/players/#{@game.black.id}"}>
          <%= @game.black.name %>
        </.link>
      </span>
      <span><.score color={:black} result={@game.result} /></span>
    </div>
    """
  end

  attr(:winner, :boolean)

  def white_square(assigns) do
    ~H"""
    <div class={[
      "inline-block align-text-bottom rounded-sm w-4 h-4 mr-1 border border-zinc-600",
      @winner && "ring-2 ring-emerald-600 ring-opacity-40"
    ]}>
    </div>
    """
  end

  attr(:winner, :boolean)

  def black_square(assigns) do
    ~H"""
    <div class={[
      "inline-block align-text-bottom rounded-sm w-4 h-4 mr-1 bg-cyan-800",
      @winner && "ring-2 ring-emerald-600 ring-opacity-40"
    ]}>
    </div>
    """
  end

  attr(:color, :atom, values: [:white, :black])
  attr(:result, :integer)
  attr(:highlight, :boolean)

  def score(%{color: :white} = assigns) do
    ~H"""
    <span :if={@result == 1} class="font-mono">1</span>
    <span :if={@result == 0}>&half;</span>
    <span :if={@result == -1} class="font-mono">0</span>
    <span :if={is_nil(@result)} class="font-mono">-</span>
    """
  end

  def score(%{color: :black} = assigns) do
    ~H"""
    <span :if={@result == 1} class="font-mono">0</span>
    <span :if={@result == 0}>&half;</span>
    <span :if={@result == -1} class="font-mono">1</span>
    <span :if={is_nil(@result)} class="font-mono">-</span>
    """
  end

  attr(:change, :integer, required: true)

  def rating_change(%{change: change} = assigns) when change > 0 do
    ~H"""
    <span class="text-emerald-600">+<%= @change %></span>
    """
  end

  def rating_change(%{change: 0} = assigns) do
    ~H"""
    <span>+<%= @change %></span>
    """
  end

  def rating_change(%{change: change} = assigns) when change < 0 do
    ~H"""
    <span class="text-red-600"><%= @change %></span>
    """
  end
end
