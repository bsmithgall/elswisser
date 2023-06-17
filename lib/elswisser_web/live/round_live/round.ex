defmodule ElswisserWeb.RoundLive.Round do
  use ElswisserWeb, :live_view

  alias Elswisser.Games
  alias Elswisser.Rounds

  embed_templates("round_html/*")

  @impl true
  def mount(_params, session, socket) do
    rnd = fetch_round(session["round_id"])

    {:ok, socket |> assign(:round, rnd) |> assign(:games, rnd.games), layout: false}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%= for game <- @games do %>
      <.game_form game={game} />
    <% end %>

    <table class="w-[40rem] mt-11 sm:w-full">
      <thead class="text-sm text-left leading-6 text-zinc-500">
        <tr>
          <th class="pl-2 pr-6 pb-2 font-normal">White</th>
          <th class="pl-2 pr-6 pb-2 font-normal">Black</th>
          <th class="pl-2 pr-6 pb-2 font-normal">Result</th>
          <th class="pl-2 pr-6 pb-2 font-normal">Actions</th>
        </tr>
      </thead>
      <tbody class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700">
        <%= for game <- @games do %>
          <.game_result_table_row game={game} />
        <% end %>
      </tbody>
    </table>
    """
  end

  @impl true
  def handle_event("save-result", params, socket) do
    game = Games.get_game!(params["id"])

    case Games.update_game(game, params) do
      {:ok, game} ->
        {:noreply,
         socket
         |> assign(
           :games,
           update_session_game(socket.assigns[:games], game.id, %{result: game.result})
         )}

      {:error, %Ecto.Changeset{} = _changeset} ->
        {:error, socket}
    end
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
  def handle_info({:pgn_result, %{pgn: pgn, game_id: game_id}}, socket) do
    {:noreply,
     socket |> assign(:games, update_session_game(socket.assigns[:games], game_id, %{pgn: pgn}))}
  end

  @impl true
  def handle_info({:pgn_error, msg}, socket) do
    {:noreply, socket |> put_flash(:error, "Error getting PGN from game link: #{msg}")}
  end

  attr(:game, :map, required: true)

  def game_form(assigns)

  attr(:game, :map, required: true)

  def game_result_table_row(assigns)

  defp fetch_round(round_id) do
    Rounds.get_round_with_games!(round_id)
  end

  # Given an update to an individual game, merge the update into the socket's
  # round property to avoid a fetch roundtrip to the database.
  defp update_session_game(games, game_id, game_attributes) when is_map(game_attributes) do
    Enum.map(games, fn g ->
      if g.id == game_id, do: Map.merge(g, game_attributes), else: g
    end)
  end
end
