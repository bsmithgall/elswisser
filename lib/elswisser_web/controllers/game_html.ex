defmodule ElswisserWeb.GameHTML do
  use ElswisserWeb, :html

  embed_templates("game_html/*")

  @doc """
  Renders a game form.
  """
  attr(:changeset, Ecto.Changeset, required: true)
  attr(:action, :string, required: true)

  def game_form(assigns)

  attr(:class, :string, default: nil)
  attr(:white, :string, required: true)
  attr(:black, :string, required: true)
  attr(:result, :integer, required: true)

  def result(assigns) do
    assigns =
      assign(
        assigns,
        case assigns.result do
          -1 -> %{white_result: "0", black_result: "1"}
          0 -> %{white_result: "&half;", black_result: "&half;"}
          1 -> %{white_result: "1", black_result: "0"}
          _ -> %{white_result: nil, black_result: nil}
        end
      )

    ~H"""
    <div class={[@class]}>
      <span class={["pr-1", @result == 1 && "font-bold"]}>
        <%= @white %> <%= raw(@white_result) %>
      </span>
      &#8212;
      <span class={["pl-1", @result == -1 && "font-bold"]}>
        <%= @black %> <%= raw(@black_result) %>
      </span>
      <span :if={is_nil(@result)}>(Unplayed)</span>
    </div>
    """
  end
end
