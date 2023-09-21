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
    attr(:width, :string)
    attr(:hide_border, :boolean)
  end

  def scores_table(assigns)

  attr(:outer, :map, required: true)
  attr(:inner, :map, required: true)

  def crosscell(assigns) do
    result_idx =
      Enum.find_index(assigns.outer.opponents, fn o -> o == assigns.inner.player_id end)

    result =
      case is_nil(result_idx) do
        true -> nil
        false -> Enum.at(assigns.outer.results, result_idx)
      end

    is_self = assigns.outer.player_id == assigns.inner.player_id

    title =
      cond do
        is_self -> assigns.outer.player.name
        is_nil(result) -> nil
        true -> "#{assigns.outer.player.name} vs #{assigns.inner.player.name}"
      end

    assigns =
      assigns |> assign(:is_self, is_self) |> assign(:result, result) |> assign(:title, title)

    ~H"""
    <td class="border border-zinc-200" title={@title}>
      <span :if={@is_self}><.icon name="hero-x-mark-solid" /></span>
      <span :if={is_nil(@result)}></span>
      <span :if={@result == 0.5}>&half;</span>
      <span :if={@result != 0.5}><%= @result %></span>
    </td>
    """
  end

  attr(:top, :integer, required: true)
  attr(:bot, :integer, required: true)

  def percentage(%{top: _top, bot: 0} = assigns) do
    ~H"""
    <span class="text-[10px]">(0%)</span>
    """
  end

  def percentage(assigns) do
    assigns = assigns |> assign(:p, (assigns.top / assigns.bot * 100) |> Float.round(1))

    ~H"""
    <span class="text-[10px]">(<%= @p %>%)</span>
    """
  end

  attr(:player, :map, required: true)

  def player_link(assigns) do
    ~H"""
    <.link class="underline" href={~p"/players/#{@player}"}>
      <%= @player.name %> (<%= @player.rating %>)
    </.link>
    """
  end
end
