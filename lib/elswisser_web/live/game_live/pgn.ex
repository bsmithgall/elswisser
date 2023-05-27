defmodule ElswisserWeb.GameLive.Pgn do
  use ElswisserWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.flash title="PGN Update" flash={@flash} kind={:info} />
      <.flash title="PGN Update" flash={@flash} kind={:error} />

      <%= if is_nil(@pgn) do %>
        <.button
          phx-click="generate-pgn"
          phx-value-game-link={@game_link}
          phx-value-game-id={@game_id}
        >
          Generate PGN
        </.button>
      <% else %>
        <p><%= @pgn %></p>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    {:ok,
     socket
     |> assign(:game_link, session["game_link"])
     |> assign(:game_id, session["game_id"])
     |> assign(:pgn, session["pgn"]), layout: false}
  end

  @impl true
  def handle_event("generate-pgn", params, socket) do
    pid = self()

    cond do
      is_nil(params["game-link"]) ->
        {:noreply, socket |> put_flash(:error, "Could not find game link!")}

      String.contains?(params["game-link"], "chess.com/") ->
        Task.start(fn ->
          case Elswisser.Games.Chesscom.fetch_pgn(params["game-link"]) do
            {:ok, pgn} -> send(pid, {:pgn_result, [pgn: pgn, id: params["game-id"]]})
            {:error, error} -> send(pid, {:pgn_error, error})
          end
        end)

        {:noreply, socket |> put_flash(:info, "Fetching PGN from chess.com")}

      String.contains?(params["game-link"], "lichess.org/") ->
        socket = put_flash(socket, :info, "Fetching PGN from lichess.org")

        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:pgn_result, result}, socket) do
    game = Elswisser.Games.get_game!(result[:id])

    case Elswisser.Games.update_game(game, %{pgn: result[:pgn]}) do
      {:ok, _game} ->
        {:noreply, assign(socket, pgn: result[:pgn])}

      {:error, %Ecto.Changeset{} = _changeset} ->
        {:error, socket}
    end
  end

  @impl true
  def handle_info({:pgn_error, msg}, socket) do
    {:noreply, socket |> put_flash(:error, "Error getting PGN from game link! " + msg)}
  end
end
