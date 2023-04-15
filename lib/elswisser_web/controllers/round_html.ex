defmodule ElswisserWeb.RoundHTML do
  use ElswisserWeb, :html

  embed_templates("round_html/*")

  @doc """
  Renders a round form.
  """
  attr(:changeset, Ecto.Changeset, required: true)
  attr(:action, :string, required: true)

  def round_form(assigns)

  attr(:result, :integer)

  def result(assigns) do
    ~H"""
    <.input
      name="result"
      type="select"
      options={["White won": "1", "Black won": -1, Draw: 0]}
      value={@result}
    />
    """
  end
end
