defmodule ElswisserWeb.RoundHTML do
  use ElswisserWeb, :html

  embed_templates("round_html/*")

  @doc """
  Renders a round form.
  """
  attr(:changeset, Ecto.Changeset, required: true)
  attr(:action, :string, required: true)

  def round_form(assigns)
end
