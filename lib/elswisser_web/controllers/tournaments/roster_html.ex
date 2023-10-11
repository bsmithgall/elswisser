defmodule ElswisserWeb.Tournaments.RosterHTML do
  use ElswisserWeb, :html
  import ElswisserWeb.PlayerHTML, only: [player_form: 1]

  embed_templates "roster_html/*"

  attr(:player, :map, required: true)
  attr(:checked, :boolean)
  attr(:current_user, :map, default: nil)

  def player_checkbox(assigns) do
    assigns = Phoenix.Component.assign_new(assigns, :checked, fn -> false end)

    ~H"""
    <label class="flex items-center gap-4 text-sm leading-6 text-zinc-600">
      <input
        :if={@current_user}
        class="rounded border-zinc-300 text-zinc-900 focus:ring-0"
        type="checkbox"
        name="player_ids[]"
        value={@player.id}
        checked={@checked}
      />
      <%= @player.name %> (<%= @player.rating %>)
    </label>
    """
  end
end
