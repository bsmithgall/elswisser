defmodule ElswisserWeb.RoundLive.Round do
  alias Elswisser.Pairings.Bye
  use ElswisserWeb, :live_view

  alias Elswisser.Games
  alias Elswisser.Rounds

  embed_templates("round_html/*")

  @impl true
  def mount(_params, session, socket) do
    rnd = fetch_round(session["round_id"])

    {:ok, socket |> assign(%{round: rnd, display: :pairings}), layout: false}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.flash id="round-success-flash" kind={:info} title="Success!" flash={@flash} />
    <.flash id="round-error-flash" kind={:error} title="Error!" flash={@flash} />

    <.round_header round={@round} display={@display} />

    <%= for game <- @round.games do %>
      <.game_form game={game} />
    <% end %>

    <.results_table :if={@display == :pairings} games={@round.games} status={@round.status} />
    <.pairings_share :if={@display == :share} games={@round.games} number={@round.number} />
    """
  end

  @impl true
  def handle_event("save-result", params, socket) when not is_map_key(params, "id") do
    {:noreply, socket}
  end

  @impl true
  def handle_event("save-result", %{"id" => id} = params, socket) do
    game = find_game(socket, id)

    case Games.update_game(game, params) do
      {:ok, game} ->
        {:noreply,
         socket
         |> assign(
           :games,
           update_session_game(socket.assigns[:games], game.id, %{
             result: game.result,
             pgn: game.pgn,
             game_link: game.game_link
           })
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
  def handle_event("switch-player-colors", %{"id" => id_str}, socket) do
    game = find_game(socket, id_str)

    case Games.update_game(game, %{white_id: game.white.id, black_id: game.black.id}) do
      {:ok, _updated} ->
        {:noreply,
         socket
         |> assign(
           :games,
           update_session_game(socket.assigns[:games], game.id, %{
             black: game.white,
             white: game.black
           })
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, socket |> put_flash(:error, "Could not switch colors: #{changeset}")}
    end
  end

  @impl true
  def handle_event("unpair-players", %{"id" => id}, socket) do
    game = find_game(socket, id)

    with {:ok, _deleted} <- Games.delete_game(game),
         {:ok, _} <- Rounds.set_pairing(socket.assigns[:round]) do
      {:noreply,
       socket |> assign(:games, Enum.filter(socket.assigns[:games], fn g -> g.id != game.id end))}
    else
      {:error, reason} ->
        {:error, socket |> put_flash(:error, "Could not delete players: #{reason}")}
    end
  end

  @impl true
  def handle_event("toggle-display", %{"display" => display}, socket) do
    {:noreply, socket |> assign(:display, if(display == "share", do: :share, else: :pairings))}
  end

  @impl true
  def handle_event("flash-copy-success", _params, socket) do
    {:noreply, socket |> put_flash(:info, "Successfully copied to clipboard!")}
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

  attr(:display, :string, required: true)
  attr(:round, :map, required: true)

  def round_header(assigns)

  attr(:game, :map, required: true)

  def game_form(assigns)

  attr(:games, :list, required: true)
  attr(:status, :string, required: true)

  def results_table(assigns)

  attr(:game, :map, required: true)
  attr(:disabled, :boolean, required: true)
  attr(:bye, :boolean, required: true)

  def game_result_table_row(assigns)

  attr(:games, :list, required: true)
  attr(:number, :integer, required: true)

  def pairings_share(assigns)

  attr(:black, :boolean, default: false)
  attr(:player, :map, required: true)

  def pairings_share_player(assigns)

  defp fetch_round(round_id) do
    Rounds.get_round_with_games_and_players!(round_id)
  end

  # Given an update to an individual game, merge the update into the socket's
  # round property to avoid a fetch roundtrip to the database.
  defp update_session_game(games, game_id, game_attributes) when is_map(game_attributes) do
    Enum.map(games, fn g ->
      if g.id == game_id, do: Map.merge(g, game_attributes), else: g
    end)
  end

  defp find_game(socket, id) when is_binary(id) do
    find_game(socket, String.to_integer(id))
  end

  defp find_game(socket, id) when is_integer(id) do
    Enum.find(socket.assigns[:games], fn g -> g.id == id end)
  end
end
