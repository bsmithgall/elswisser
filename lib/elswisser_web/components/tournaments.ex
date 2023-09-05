defmodule ElswisserWeb.TournamentLayouts do
  use ElswisserWeb, :html
  import ElswisserWeb.Layouts
  import ElswisserWeb.CoreComponents

  embed_templates("tournaments/*")

  attr(:href, :string, required: true)
  attr(:label, :string, required: true)
  attr(:icon, :string, default: nil)
  attr(:icon_class, :string, default: nil)
  attr(:active, :boolean, default: false)

  def navlink(assigns) do
    ~H"""
    <div
      class={["hover:bg-slate-300 cursor-pointer rounded-md p-1", @active && "bg-slate-200"]}
      phx-click={JS.navigate(@href)}
    >
      <span :if={@icon != nil} class={[@icon, @icon_class, "-mt-1"]} />
      <a href={@href}><%= @label %></a>
    </div>
    """
  end

  attr(:tournament, :map, required: true)
  attr(:current_round, :map, required: true)

  def new_round_form(assigns) do
    ~H"""
    <.form
      :if={@current_round.number < @tournament.length}
      for={nil}
      class="mt-4"
      action={~p"/tournaments/#{@tournament}/rounds"}
      method="POST"
    >
      <input type="hidden" value={@current_round.number} name="number" />
      <.button
        type="submit"
        class="text-center"
        disabled={@current_round.status != :complete and @current_round.number != 0}
      >
        <.icon class="mr-2 -mt-1" name="hero-plus" />Add new round
      </.button>
    </.form>
    """
  end

  attr(:tournament, :map, required: true)
  attr(:current_round, :map, required: true)
  attr(:active, :string, default: nil)
  attr(:current_user, :map, required: true)

  def sidenav(assigns)

  defp icon_by_round_status(rnd) do
    case rnd.status do
      :pairing -> "hero-adjustments-horizontal-mini"
      :playing -> "hero-play-circle-mini"
      :complete -> "hero-check-circle-mini"
      _ -> "hero-question-mark-circle-mini"
    end
  end

  defp icon_class_by_round_status(rnd) do
    case rnd.status do
      :complete -> "bg-emerald-800"
      _ -> nil
    end
  end
end
