defmodule ElswisserWeb.RoundLive.Pairing do
  use ElswisserWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
