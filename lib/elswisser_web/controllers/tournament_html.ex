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

  @doc """
  Renders the score detail table
  """
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

  attr :outer, :map, required: true
  attr :inner, :map, required: true

  def crosscell(assigns) do
    result_idx = Enum.find_index(assigns.outer.opponents, fn o -> o == assigns.inner.id end)

    result =
      case is_nil(result_idx) do
        true -> nil
        false -> Enum.at(assigns.outer.results, result_idx)
      end

    assigns = assign(assigns, :is_self, assigns.outer.id == assigns.inner.id)
    assigns = assign(assigns, :result, result)

    ~H"""
    <td class="border-r border-zinc-200 hover:bg-zinc-100">
      <span :if={@is_self}><.icon name="hero-x-mark-solid" /></span>
      <span :if={is_nil(@result)}></span>
      <span :if={@result == 0.5}>&half;</span>
      <span :if={@result != 0.5}><%= @result %></span>
    </td>
    """
  end
end
