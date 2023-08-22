defmodule ElswisserWeb.TournamentHTML do
  require Integer
  use ElswisserWeb, :html

  embed_templates("tournament_html/*")

  def player_select(f, changeset) do
    existing_ids =
      changeset
      |> Ecto.Changeset.get_change(:players, [])
      |> Enum.map(& &1.data.id)

    player_opts =
      for player <- Elswisser.Players.list_players(),
          do: [key: player.name, value: player.id, selected: player.id in existing_ids]

    Phoenix.HTML.Form.multiple_select(f, :player_ids, player_opts)
  end

  @doc """
  Renders a tournament form.
  """
  attr(:changeset, Ecto.Changeset, required: true)
  attr(:action, :string, required: true)

  def tournament_form(assigns)

  @doc """
  Renders the score detail table
  """
  attr(:id, :string, required: true)
  attr(:rows, :list, required: true)

  slot :col, required: true do
    attr(:label, :string)
    attr(:center, :boolean)
    attr(:bold, :boolean)
    attr(:wide, :boolean)
    attr(:width, :integer)
  end

  def scores_table(assigns) do
    ~H"""
    <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table id={@id} class="w-[40rem] sm:w-full table-fixed">
        <thead class="text-sm text-left leading-4 text-zinc-500 border-zinc-200">
          <tr>
            <th class="w-4"></th>
            <th
              :for={col <- @col}
              class={[
                "px-2 py-1 leading-4 font-normal border-r border-zinc-200",
                col[:center] && "text-center",
                col[:width] && "w-#{col[:width]}",
                !col[:width] && "w-10"
              ]}
            >
              <%= col[:label] %>
            </th>
          </tr>
        </thead>
        <tbody
          id={@id}
          class="divide-y divide-zinc-200 border-y border-zinc-200 text-sm text-zinc-700"
        >
          <%= @rows |> Enum.with_index() |> Enum.map(fn {row, idx} -> %>
            <tr>
              <td class={[
                "px-2 text-center border border-zinc-200",
                Integer.is_even(idx) && "bg-zinc-100"
              ]}>
                <%= idx + 1 %>
              </td>
              <td
                :for={col <- @col}
                class={[
                  Integer.is_even(idx) && "bg-zinc-100",
                  "p-0 border-r border-zinc-200 m-1px",
                  col[:center] && "text-center",
                  col[:wide] && "w-40",
                  !col[:wide] && "w-8"
                ]}
              >
                <div class="py-1 px-2">
                  <%= render_slot(col, row) %>
                </div>
              </td>
            </tr>
          <% end) %>
        </tbody>
      </table>
    </div>
    """
  end

  attr(:outer, :map, required: true)
  attr(:inner, :map, required: true)

  def crosscell(assigns) do
    result_idx = Enum.find_index(assigns.outer.opponents, fn o -> o == assigns.inner.id end)

    result =
      case is_nil(result_idx) do
        true -> nil
        false -> Enum.at(assigns.outer.results, result_idx)
      end

    is_self = assigns.outer.id == assigns.inner.id

    title =
      cond do
        is_self -> assigns.outer.name
        is_nil(result) -> nil
        true -> "#{assigns.outer.name} vs #{assigns.inner.name}"
      end

    assigns =
      assigns |> assign(:is_self, is_self) |> assign(:result, result) |> assign(:title, title)

    ~H"""
    <td class="border border-zinc-200" title={title}>
      <span :if={@is_self}><.icon name="hero-x-mark-solid" /></span>
      <span :if={is_nil(@result)}></span>
      <span :if={@result == 0.5}>&half;</span>
      <span :if={@result != 0.5}><%= @result %></span>
    </td>
    """
  end
end
