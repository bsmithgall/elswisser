defmodule ElswisserWeb.Layouts do
  use ElswisserWeb, :html

  embed_templates "layouts/*"

  attr(:current_user, :map, default: nil)

  slot(:inner_hamburger)

  def topnav(assigns)

  attr(:href, :string, required: true)
  attr(:label, :string, required: true)
  attr(:icon, :string, default: nil)
  attr(:icon_class, :string, default: nil)
  attr(:active, :boolean, default: false)

  def hamburger_nav_link(assigns) do
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

  def show_hamburger(js \\ %JS{}) do
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

  def hide_hamburger(js \\ %JS{}) do
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
