defmodule ElswisserWeb.GameLive.Pgn do
  use ElswisserWeb, :live_view

  alias Elswisser.Games

  @impl true
  def mount(_params, session, socket) do
    {:ok,
     socket
     |> assign(:game_link, session["game_link"])
     |> assign(:game_id, session["game_id"])
     |> assign(:white_player, session["white_player"])
     |> assign(:black_player, session["black_player"])
     |> assign(:pgn, session["pgn"]), layout: false}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.flash title="PGN Update" flash={@flash} kind={:info} />
    <.flash title="PGN Update" flash={@flash} kind={:error} />

    <%= if is_nil(@pgn) do %>
      <.button phx-click="generate-pgn" phx-value-game-link={@game_link} phx-value-game-id={@game_id}>
        Generate PGN
      </.button>
    <% else %>
      <div id="pgn-board-container" phx-hook="GameNavigatorHook" phx-value-pgn={@pgn}>
        <span><%= @black_player %></span>
        <div id="pgn-board" class="w:40 md:w-96"></div>
        <span><%= @white_player %></span>
      </div>

      <div class="pt-2 text-center">
        <.game_nav navigate="start" icon="hero-chevron-double-left" />
        <.game_nav navigate="back" icon="hero-arrow-left" />
        <.game_nav navigate="forward" icon="hero-arrow-right" />
        <.game_nav navigate="end" icon="hero-chevron-double-right" />
      </div>
    <% end %>
    """
  end

  attr(:icon, :string, required: true)
  attr(:navigate, :string, required: true)

  def game_nav(assigns) do
    ~H"""
    <.button data-js-navigate={@navigate}>
      <.icon name={@icon} />
    </.button>
    """
  end

  @impl true
  def handle_event("generate-pgn", params, socket) do
    pid = self()

    Task.start(fn ->
      case Games.fetch_pgn(params["game-id"], params["game-link"]) do
        {:ok, result} -> send(pid, {:pgn_result, result})
        {:error, msg} -> send(pid, {:pgn_error, msg})
      end
    end)

    {:noreply, socket |> put_flash(:info, "Trying to fetch PGN!")}
  end

  @impl true
  def handle_info({:pgn_result, %{game_id: _game_id, pgn: pgn}}, socket) do
    {:noreply, assign(socket, :pgn, pgn)}
  end

  @impl true
  def handle_info({:pgn_error, msg}, socket) do
    {:noreply, socket |> put_flash(:error, "Error getting PGN from game link: #{msg}")}
  end
end
