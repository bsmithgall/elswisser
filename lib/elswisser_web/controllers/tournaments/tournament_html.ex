defmodule ElswisserWeb.Tournaments.TournamentHTML do
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
end
