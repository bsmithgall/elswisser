defmodule ElswisserWeb.Elchesser.Live do
  use ElswisserWeb, :live_view

  def render(assigns) do
    ~H"""
    <.live_component module={ElchesserWeb.LiveGame} id="live-game" />
    """
  end
end
