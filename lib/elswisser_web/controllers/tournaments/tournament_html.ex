defmodule ElswisserWeb.Tournaments.TournamentHTML do
  require Integer
  require IEx
  alias Elswisser.Tournaments.Tournament
  alias Phoenix.HTML.Form
  use ElswisserWeb, :html

  embed_templates("tournament_html/*")

  def player_select(f, changeset) do
    existing_ids =
      changeset
      |> Ecto.Changeset.get_field(:players, [])
      |> Enum.map(& &1.id)

    player_opts =
      for player <- Elswisser.Players.list_players(),
          do: [key: player.name, value: player.id, selected: player.id in existing_ids]

    Form.multiple_select(f, :player_ids, player_opts)
  end

  def selected_players(changeset) do
    changeset
    |> Ecto.Changeset.get_field(:players, [])
    |> Enum.map(& &1.id)
  end

  def player_opts() do
    Elswisser.Players.list_players()
    |> Enum.map(fn p -> [key: p.name, value: p.id] end)
  end

  def tournament_opts() do
    Ecto.Enum.values(Tournament, :type)
    |> Enum.map(&[key: Phoenix.Naming.humanize(&1), value: &1])
  end

  @doc """
  Renders a tournament form.
  """
  attr(:changeset, Ecto.Changeset, required: true)
  attr(:action, :string, required: true)
  attr(:new, :boolean, default: true)

  def tournament_form(assigns)
end
