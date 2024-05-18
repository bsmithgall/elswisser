defmodule ElswisserWeb.Tournaments.TournamentHTML do
  alias Elswisser.Tournaments.Tournament
  use ElswisserWeb, :html

  embed_templates("tournament_html/*")

  def selected_players(changeset, field \\ :players) do
    changeset
    |> Ecto.Changeset.get_field(field, [])
    |> Enum.map(& &1.id)
  end

  def player_opts() do
    Elswisser.Players.list_players() |> Enum.map(&[key: &1.name, value: &1.id])
  end

  def player_tuples() do
    Elswisser.Players.list_players() |> Enum.map(&{&1.name, &1.id})
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
