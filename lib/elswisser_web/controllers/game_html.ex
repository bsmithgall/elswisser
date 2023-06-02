defmodule ElswisserWeb.GameHTML do
  use ElswisserWeb, :html

  embed_templates("game_html/*")

  @doc """
  Renders a game form.
  """
  attr(:changeset, Ecto.Changeset, required: true)
  attr(:action, :string, required: true)

  def game_form(assigns)

  attr(:white, :string, required: true)
  attr(:black, :string, required: true)
  attr(:result, :integer, required: true)

  def result(assigns) do
    {white_result, black_result} =
      case assigns.result do
        -1 -> {"0", "1"}
        0 -> {"&half;", "&half;"}
        1 -> {"1", "0"}
      end

    assigns = assign(assigns, :white_result, white_result)
    assigns = assign(assigns, :black_result, black_result)

    ~H"""
    <span class={["pr-1", @result == 1 && "font-bold"]}><%= @white %> <%= raw(@white_result) %></span>
    <span>&#8212;</span>
    <span class={["pl-1", @result == -1 && "font-bold"]}>
      <%= @black %> <%= raw(@black_result) %>
    </span>
    """
  end
end
