defmodule ElswisserWeb.TournamentLayouts do
  use ElswisserWeb, :html
  import ElswisserWeb.Layouts
  import ElswisserWeb.CoreComponents

  embed_templates("tournaments/*")

  attr(:tournament, :map, required: true)

  def sidenav(assigns) do
    ~H"""
    <aside class="flex flex-col grow px-4 pt-2 border-r border-r-slate-200 h-[calc(100vh-62px)] overflow-y">
      <div class="flex place-content-center pb-2">
        <h1 class="text-lg font-semibold leading-8 text-zinc-800">
        <.link href={~p"/tournaments/#{@tournament}"}><%= @tournament.name %></.link>
        </h1>
      </div>
      <hr />
      <div>
        <.navlink label="Roster" href="#" icon="hero-user-group" />
        <.navlink label="Scores" href="#" icon="hero-list-bullet" />
        <.navlink label="Crosstable" href="#" icon="hero-table-cells" />
        <.navlink label="Stats" href="#" icon="hero-chart-bar-square" />
      </div>
      <hr />
      <div>
        <h2 class="mt-2 text-sm leading-6 text-zinc-600 pl-1 pb-1">
          Rounds
        </h2>
        <%= for rnd <- @tournament.rounds do %>
          <.navlink
            href={~p"/tournaments/#{rnd.tournament_id}/rounds/#{rnd}"}
            label={"Round #{rnd.number}"}
          />
        <% end %>
      </div>
    </aside>
    """
  end

  attr(:href, :string, required: true)
  attr(:label, :string, required: true)
  attr(:icon, :string, default: nil)

  def navlink(assigns) do
    ~H"""
    <div class="hover:bg-slate-300 cursor-pointer rounded-md p-1">
      <.icon :if={@icon != nil} name={@icon} />
      <a href={@href}><%= @label %></a>
    </div>
    """
  end
end
