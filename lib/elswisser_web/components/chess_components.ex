defmodule ElswisserWeb.ChessComponents do
  @moduledoc """
  Similar to core_components, this is meant to provide shared components for
  representations of different things across the application. Of course, the
  application is wildly different because I am just hacking this together as I
  go, but what can you do.
  """

  import ElswisserWeb.CoreComponents
  import Phoenix.HTML, only: [raw: 1]

  use Phoenix.Component
  use Phoenix.VerifiedRoutes, endpoint: ElswisserWeb.Endpoint, router: ElswisserWeb.Router

  alias Elswisser.Players

  attr(:game, :map, required: true)
  attr(:highlight, :atom, values: [:white, :black, nil], default: nil)
  attr(:class, :string, default: nil)

  def game_result(assigns) do
    ~H"""
    <div class={["grid grid-cols-3 grid-rows-2 gap-x-4 min-w-min", @class && @class]}>
      <span class="col-span-2">
        <.white_square winner={@game.result == 1} />
        <.link
          class={["hover:underline", @highlight == :white && "font-bold"]}
          href={~p"/players/#{@game.white.id}"}
        >
          <%= @game.white.name %><span :if={@game.white_rating}> (<%= @game.white_rating %>)</span>
        </.link>
      </span>
      <span><.score color={:white} result={@game.result} /></span>
      <span class="col-span-2">
        <.black_square winner={@game.result == -1} />
        <.link
          class={["hover:underline", @highlight == :black && "font-bold"]}
          href={~p"/players/#{@game.black.id}"}
        >
          <%= @game.black.name %><span :if={@game.black_rating}> (<%= @game.black_rating %>)</span>
        </.link>
      </span>
      <span><.score color={:black} result={@game.result} /></span>
    </div>
    """
  end

  attr(:game_link, :string, default: nil)

  def has_game_link(assigns) do
    ~H"""
    <span :if={is_nil(@game_link)}>
      <.icon class="-ml-1 mr-1 h-4 w-4" name="hero-no-symbol-mini" />Link
    </span>
    <span :if={!is_nil(@game_link)}>
      <.icon class="-ml-1 mr-1 h-4 w-4" name="hero-check-mini" />
      <.link class="hover:underline" href={@game_link}>
        Link
      </.link>
    </span>
    """
  end

  attr(:pgn, :string, default: nil)

  def has_pgn(assigns) do
    ~H"""
    <span :if={is_nil(@pgn)} class="self-center">
      <.icon class="-ml-1 mr-1 h-4 w-4" name="hero-no-symbol-mini" />PGN
    </span>
    <span :if={!is_nil(@pgn)} class="self-center">
      <.icon class="-ml-1 mr-1 h-4 w-4" name="hero-check-mini" />PGN
    </span>
    """
  end

  attr(:winner, :boolean)

  def white_square(assigns) do
    ~H"""
    <div class={[
      "inline-block align-text-bottom rounded-sm w-4 h-4 mr-1 border border-zinc-600",
      @winner && "ring-2 ring-emerald-600 ring-opacity-40 bg-boardwhite"
    ]}>
    </div>
    """
  end

  attr(:winner, :boolean)

  def black_square(assigns) do
    ~H"""
    <div class={[
      "inline-block align-text-bottom rounded-sm w-4 h-4 mr-1 bg-boardblack",
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

  attr(:class, :string, default: nil)
  attr(:white, :string, required: true)
  attr(:black, :string, required: true)
  attr(:result, :integer, required: true)
  attr(:nopad, :boolean, default: false)

  def result(assigns) do
    assigns =
      assign(
        assigns,
        case assigns.result do
          -1 -> %{white_result: "0", black_result: "1"}
          0 -> %{white_result: "&half;", black_result: "&half;"}
          1 -> %{white_result: "1", black_result: "0"}
          _ -> %{white_result: nil, black_result: nil}
        end
      )

    ~H"""
    <div class={[@class]}>
      <span class={[!@nopad && "pr-1", @result == 1 && "font-bold"]}>
        <%= @white %> <%= raw(@white_result) %>
      </span>
      &#8212;
      <span class={[!@nopad && "pl-1", @result == -1 && "font-bold"]}>
        <%= @black %> <%= raw(@black_result) %>
      </span>
      <span :if={is_nil(@result)}>(Unplayed)</span>
    </div>
    """
  end

  attr(:player, :map)
  attr(:black, :boolean, default: false)

  def player_card(%{player: %Ecto.Association.NotLoaded{}}) do
    player_card(%{player: nil})
  end

  def player_card(%{player: nil} = assigns) do
    ~H"""
    <div class="w-full">
      <.header><span class={@black && "text-boardwhite-lighter"}>Select player</span></.header>

      <.condensed_list
        dt_color={if @black, do: "text-boardwhite-lighter", else: "text-zinc-500"}
        dd_color={if @black, do: "text-boardwhite", else: "text-zinc-700"}
        divide_color={if @black, do: "divide-boardblack-lighter", else: "divide-boardwhite-darker"}
      >
        <:item title="Score"></:item>
        <:item title="Rating"></:item>
        <:item title="White Games"></:item>
        <:item title="Black Games"></:item>
      </.condensed_list>
    </div>
    <hr class={[
      "h-px my-4 border-0",
      if(@black, do: "bg-boardblack-lighter", else: "bg-boardwhite-darker")
    ]} />
    <div class="w-full">
      <.section_title class="mb-4">
        <span class={@black && "text-boardwhite-lighter"}>Tournament History</span>
      </.section_title>
    </div>
    """
  end

  def player_card(%{player: player} = assigns) do
    all_games = Players.Player.all_games(player)

    assigns =
      assign(assigns, %{
        games: all_games,
        score: Elswisser.Scores.raw_score_for_player(all_games, assigns[:player].id)
      })

    ~H"""
    <div class="w-full">
      <.header><span class={@black && "text-boardwhite-lighter"}><%= @player.name %></span></.header>

      <.condensed_list
        dt_color={if @black, do: "text-boardwhite-lighter", else: "text-zinc-500"}
        dd_color={if @black, do: "text-boardwhite", else: "text-zinc-700"}
        divide_color={if @black, do: "divide-boardblack-lighter", else: "divide-boardwhite-darker"}
      >
        <:item title="Score"><%= @score %></:item>
        <:item title="Rating"><%= @player.rating %></:item>
        <:item title="White Games"><%= length(@player.white_games) %></:item>
        <:item title="Black Games"><%= length(@player.black_games) %></:item>
      </.condensed_list>
    </div>
    <hr class={[
      "h-px my-4 border-0",
      if(@black, do: "bg-boardblack-lighter", else: "bg-boardwhite-darker")
    ]} />
    <div class="w-full">
      <.section_title class="mb-4">
        <span class={@black && "text-boardwhite-lighter"}>Tournament History</span>
      </.section_title>
      <ol class="list-decimal text-sm pl-4">
        <%= for game <- @games do %>
          <li class="pb-1">
            <.link
              class="underline block"
              href={~p"/tournaments/#{game.tournament_id}/games/#{game.id}"}
            >
              <.result white={game.white.name} black={game.black.name} result={game.result} nopad />
            </.link>
          </li>
        <% end %>
      </ol>
    </div>
    """
  end

  attr(:white, :map)
  attr(:black, :map)

  def matchup(assigns) do
    ~H"""
    <div class="md:flex flex-row justify-center gap-2">
      <div class="md:w-1/2">
        <.section_title class="text-xs text-center uppercase mb-4">White</.section_title>
        <div class="mb-4 md:mb-0 p-4 bg-boardwhite rounded-md border border-solid border-zinc-400">
          <.player_card player={@white} />
        </div>
      </div>
      <div class="md:w-1/2">
        <.section_title class="text-xs text-center uppercase mb-4">Black</.section_title>
        <div class="mb-4 md:mb-0 p-4 bg-boardblack text-boardwhite rounded-md border border-solid border-zinc-400">
          <.player_card player={@black} black={true} />
        </div>
      </div>
    </div>
    """
  end
end
