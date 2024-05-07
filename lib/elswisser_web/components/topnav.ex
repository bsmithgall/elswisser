defmodule ElswisserWeb.Topnav do
  import ElswisserWeb.CoreComponents, only: [icon: 1]

  use Phoenix.Component
  use Phoenix.VerifiedRoutes, endpoint: ElswisserWeb.Endpoint, router: ElswisserWeb.Router
  alias Phoenix.LiveView.JS

  attr(:current_user, :map, default: nil)
  slot(:inner_hamburger)

  def nav(assigns) do
    ~H"""
    <header class="px-4 md:px-6 lg:px-8">
      <div class="flex items-center justify-between border-b border-zinc-100 py-3 text-sm">
        <div class="flex items-center gap-4">
          <a href="/">
            <img src="/images/elswisser.svg" class="w-6 md:w-8" />
          </a>
          <p class="bg-brand/5 text-brand rounded-sm px-2 font-medium leading-6">
            Elswisser
          </p>
        </div>
        <div class="md:hidden">
          <button phx-click={show_hamburger()}>
            <.icon name="hero-ellipsis-vertical-mini" />
          </button>
        </div>
        <div class="hidden md:flex md:items-center md:gap-4 font-semibold leading-6 text-zinc-900">
          <a href={~p"/game"} class="hover:text-zinc-500">Play</a>
          <a href={~p"/tournaments"} class="hover:text-zinc-500">
            Tournaments
          </a>
          <a href={~p"/players"} class="hover:text-zinc-500 border-r border-zinc-200 pr-4">
            Players
          </a>
          <.link
            :if={@current_user}
            href={~p"/accounts/users/log_out"}
            method="delete"
            class="hover:text-zinc-500"
          >
            Log out
          </.link>
          <.link :if={!@current_user} href={~p"/accounts/users/log_in"} class="hover:text-zinc-500">
            Log in
          </.link>
        </div>
      </div>
      <div id="hamburger-container" class="hidden relative z-50">
        <div id="hamburger-backdrop" class="fixed inset-0 bg-zinc-50/90  transition-opacity"></div>
        <nav
          id="hamburger-content"
          class="fixed top-0 left-0 bottom-0 flex flex-col grow justify-between w-3/4 max-w-sm py-6 bg-white border-r overflow-y-auto"
        >
          <div>
            <div class="flex items-center mb-4 place-content-between mx-4 border-b-zinc-200">
              <div class="flex items-center gap-4">
                <a href="/">
                  <img src="/images/elswisser.svg" width="32" />
                </a>
                <p class="bg-brand/5 text-brand rounded-sm px-2 font-medium leading-6">
                  Elswisser
                </p>
              </div>
              <button class="navbar-close" phx-click={hide_hamburger()}>
                <.icon name="hero-x-mark-mini" />
              </button>
            </div>
            <div :if={@inner_hamburger != []}>
              <%= render_slot(@inner_hamburger) %>
            </div>
          </div>
          <div>
            <ul>
              <.hamburger_nav_link href={~p"/game"} label="Play" />
              <.hamburger_nav_link href={~p"/tournaments"} label="Tournaments" />
              <.hamburger_nav_link href={~p"/players"} label="Players" />
              <.hamburger_nav_link
                :if={!@current_user}
                href={~p"/accounts/users/log_in"}
                label="Log in"
              />
              <.hamburger_nav_link
                :if={@current_user}
                href={~p"/accounts/users/log_out"}
                label="Log out"
              />
            </ul>
          </div>
        </nav>
      </div>
    </header>
    """
  end

  attr(:href, :string, required: true)
  attr(:label, :string, required: true)
  attr(:icon, :string, default: nil)
  attr(:icon_class, :string, default: nil)
  attr(:active, :boolean, default: false)

  defp hamburger_nav_link(assigns) do
    ~H"""
    <li
      class={["block px-4 py-2 text-sm font-semibold hover:bg-slate-300", @active && "bg-slate-200"]}
      phx-click={JS.navigate(@href)}
    >
      <span :if={@icon != nil} class={[@icon, @icon_class, "-mt-1"]} />
      <a href={@href}><%= @label %></a>
    </li>
    """
  end

  defp show_hamburger(js \\ %JS{}) do
    js
    |> JS.show(
      to: "#hamburger-content",
      transition:
        {"transition-all transform ease-in-out duration-300", "-translate-x-3/4", "translate-x-0"},
      time: 300,
      display: "flex"
    )
    |> JS.show(
      to: "#hamburger-backdrop",
      transition:
        {"transition-all transform ease-in-out duration-300", "opacity-0", "opacity-100"}
    )
    |> JS.show(
      to: "#hamburger-container",
      time: 300
    )
    |> JS.add_class("overflow-hidden", to: "body")
  end

  defp hide_hamburger(js \\ %JS{}) do
    js
    |> JS.hide(
      to: "#hamburger-backdrop",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> JS.hide(
      to: "#hamburger-content",
      transition:
        {"transition-all transform ease-in duration-200", "translate-x-0", "-translate-x-3/4"}
    )
    |> JS.hide(to: "#hamburger-container", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
  end
end
