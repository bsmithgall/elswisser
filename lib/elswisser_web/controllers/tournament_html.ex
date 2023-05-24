defmodule ElswisserWeb.TournamentHTML do
  use ElswisserWeb, :html

  import Phoenix.HTML.Form

  embed_templates "tournament_html/*"

  def player_select(f, changeset) do
    existing_ids =
      changeset
      |> Ecto.Changeset.get_change(:players, [])
      |> Enum.map(& &1.data.id)

    player_opts =
      for player <- Elswisser.Players.list_players(),
          do: [key: player.name, value: player.id, selected: player.id in existing_ids]

    multiple_select(f, :player_ids, player_opts)
  end

  @doc """
  Renders a tournament form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def tournament_form(assigns)

  attr :id, :string, required: true
  attr :rows, :list, required: true

  slot :col, required: true do
    attr :label, :string
    attr :center, :boolean
    attr :bold, :boolean
  end

  def scores_table(assigns) do
    ~H"""
    <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table id={@id} class="w-[40rem] sm:w-full">
        <thead class="text-sm text-left leading-4 text-zinc-500">
          <tr>
            <th
              :for={col <- @col}
              class={["p-0 pr-4 pb-2 font-normal", col[:center] && "text-center"]}
            >
              <%= col[:label] %>
            </th>
          </tr>
        </thead>
        <tbody
          id={@id}
          class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700"
        >
          <tr :for={row <- @rows} class="group hover:bg-zinc-50">
            <td :for={col <- @col} class={["relative p-0", col[:center] && "text-center"]}>
              <div class="block py-1 pr-6">
                <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50 sm:rounded-l-xl" />
                <span class="relative"><%= render_slot(col, row) %></span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end
end
