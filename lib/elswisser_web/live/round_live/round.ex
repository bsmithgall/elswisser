defmodule ElswisserWeb.RoundLive.Round do
  require Elswisser.Tournaments.Tournament
  alias Elswisser.Tournaments.Tournament
  alias Elswisser.Pairings.Bye
  use ElswisserWeb, :live_view

  alias Elswisser.Matches
  alias Elswisser.Games
  alias Elswisser.Games.PgnProvider
  alias Elswisser.Rounds
  alias Elswisser.Players

  embed_templates("round_html/*")

  @impl true
  def mount(
        _params,
        %{
          "round_id" => round_id,
          "tournament_type" => tournament_type,
          "user_token" => user_token
        },
        socket
      ) do
    rnd = fetch_round(round_id)
    roster = Players.get_tournament_partipants(rnd.tournament_id)

    {:ok,
     socket
     |> assign(round: rnd)
     |> assign(tournament_type: tournament_type)
     |> assign(
       games:
         Enum.map(rnd.games, fn g -> Map.merge(g, %{valid_link: valid_link?(g.game_link)}) end)
     )
     |> assign(roster: roster)
     |> assign(display: :pairings)
     |> assign(show_game_info: false)
     |> assign(signed_in: !is_nil(user_token)), layout: false}
  end

  @impl true
  def render(%{games: games} = assigns) when length(games) == 0 do
    ~H"""
    <.round_header
      round={@round}
      display={@display}
      signed_in={@signed_in}
      tournament_type={@tournament_type}
    />

    <.header class="mt-11">No pairings made yet!</.header>
    """
  end

  @impl true
  def render(%{display: :pairings} = assigns) do
    ~H"""
    <.flash id="round-success-flash" kind={:info} title="Success!" flash={@flash} />
    <.flash id="round-error-flash" kind={:error} title="Error!" flash={@flash} />

    <.round_header
      round={@round}
      display={@display}
      signed_in={@signed_in}
      tournament_type={@tournament_type}
    />
    <.modal
      :if={@show_game_info}
      id="game-info"
      show
      on_cancel={hide_modal("game-info") |> JS.push("hide-game-info")}
    >
      <.header class="pb-4">Round <%= @round.number %> matchup</.header>
      <.matchup white={assigns[:white]} black={assigns[:black]} />
    </.modal>

    <%= for game <- @games do %>
      <form id={"game-#{game.id}-result"} phx-change="save-result">
        <input type="hidden" name="id" value={game.id} />
      </form>

      <.game_detail_form game={game} />
    <% end %>

    <.table id="results" rows={@games}>
      <:col :let={game} label="White">
        <.result_player win={game.result == 1} draw={game.result == 0} name={game.white.name} />
      </:col>
      <:col :let={game} label="Black">
        <.result_player win={game.result == -1} draw={game.result == 0} name={game.black.name} />
      </:col>
      <:col :let={game} :if={@signed_in} label="Result">
        <.result_select
          game={game}
          disabled={@round.status == :finished}
          bye={game.black_id == Bye.bye_player_id() or game.white_id == Bye.bye_player_id()}
          tournament_type={@tournament_type}
        />
      </:col>
      <:col :let={game} label="Actions" center>
        <.result_actions
          game={game}
          signed_in={@signed_in}
          bye={game.black_id == Bye.bye_player_id() or game.white_id == Bye.bye_player_id()}
          swiss={@tournament_type == :swiss}
        />
      </:col>
    </.table>
    """
  end

  @impl true
  def render(%{display: :share} = assigns) do
    ~H"""
    <.flash id="round-success-flash" kind={:info} title="Success!" flash={@flash} />
    <.flash id="round-error-flash" kind={:error} title="Error!" flash={@flash} />

    <.round_header
      round={@round}
      display={@display}
      signed_in={@signed_in}
      tournament_type={@tournament_type}
    />

    <.pairings_share games={@games} number={@round.number} />
    """
  end

  @impl true
  def handle_event("validate-game-link", %{"game_link" => link, "id" => id}, socket) do
    {:noreply,
     socket
     |> assign(
       games:
         Enum.map(socket.assigns[:games], fn g ->
           case to_string(g.id) == id do
             true -> Map.merge(g, %{game_link: link, valid_link: valid_link?(link)})
             false -> g
           end
         end)
     )}
  end

  @impl true
  def handle_event("save-result", %{"id" => id} = params, socket) do
    with :ok <- ensure_updatable(params, socket),
         game <- find_game(socket, id),
         {:ok, game} <-
           Games.update_game(game, Map.merge(params, %{"finished_at" => DateTime.utc_now()})) do
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
    else
      {:error, reason} -> {:noreply, socket |> put_flash(:error, "#{reason}")}
    end
  end

  @impl true
  def handle_event("generate-pgn", %{"game-id" => game_id, "game-link" => game_link}, socket) do
    pid = self()

    Task.start(fn ->
      case Games.fetch_pgn(game_id, game_link) do
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
        {:noreply, socket |> put_flash(:error, "Could not switch colors: #{changeset}")}
    end
  end

  @impl true
  def handle_event("unpair-players", %{"id" => id}, socket) do
    game = find_game(socket, id)

    with {:ok, _} <- Matches.delete_from_game(game),
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
  def handle_event(
        "show-game-info",
        %{"white-id" => white_id, "black-id" => black_id},
        socket
      ) do
    tournament_id = socket.assigns[:round].tournament_id
    roster = socket.assigns[:roster]

    with {:ok, white} <- fetch_player_with_history(white_id, tournament_id, roster),
         {:ok, black} <- fetch_player_with_history(black_id, tournament_id, roster) do
      {:noreply,
       socket |> assign(:white, white) |> assign(:black, black) |> assign(:show_game_info, true)}
    else
      {:error, msg} -> {:error, socket |> put_flash(:error, msg)}
    end
  end

  @impl true
  def handle_event("hide-game-info", _params, socket) do
    {:noreply, socket |> assign(:show_game_info, false)}
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
  attr(:signed_in, :boolean, required: true)
  attr(:tournament_type, :atom, required: true)

  def round_header(assigns)

  attr(:game, :map, required: true)
  attr(:link_valid, :boolean, default: nil)

  def game_detail_form(assigns)

  attr(:games, :list, required: true)
  attr(:number, :integer, required: true)

  def pairings_share(assigns)

  attr(:black, :boolean, default: false)
  attr(:player, :map, required: true)

  def pairings_share_player(assigns)

  attr(:win, :boolean, default: false)
  attr(:draw, :boolean, default: false)
  attr(:name, :string, required: true)

  def result_player(assigns) do
    ~H"""
    <span class="w-6 inline-block">
      <.icon :if={@win} name="hero-trophy" />
      <.icon :if={@draw} name="hero-scale" />
    </span>
    <%= @name %>
    """
  end

  attr(:game, :map, required: true)
  attr(:disabled, :boolean, default: false)
  attr(:bye, :boolean, default: false)
  attr(:tournament_type, :atom, default: :swiss)

  def result_select(%{bye: true, tournament_type: type} = assigns)
      when Tournament.is_knockout?(type) do
    ~H"""
    <div class="-mt-1">
      <.input type="select" name="result" options={[Walkover: 1]} disabled={true} value={0} />
    </div>
    """
  end

  def result_select(%{bye: true} = assigns) do
    ~H"""
    <div class="-mt-1">
      <.input type="select" name="result" options={["Draw (Bye)": 0]} disabled={true} value={0} />
    </div>
    """
  end

  def result_select(%{bye: false} = assigns) do
    ~H"""
    <div class="-mt-1">
      <.input
        type="select"
        id={"game-result-#{@game.id}-result"}
        name="result"
        options={["Select Result": nil, "White won": 1, "Black won": -1, Draw: 0]}
        disabled={@disabled}
        value={@game.result}
        form={"game-#{@game.id}-result"}
        class="z-10 relative"
      />
    </div>
    """
  end

  attr(:game, :map, required: true)
  attr(:signed_in, :boolean, default: false)
  attr(:bye, :boolean, default: false)
  attr(:swiss, :boolean, required: true)

  def result_actions(assigns) do
    ~H"""
    <button
      phx-click="show-game-info"
      phx-value-white-id={@game.white_id}
      phx-value-black-id={@game.black_id}
      title="Show matchup information"
    >
      <.icon class="-mt-1 ml-4" name="hero-question-mark-circle" />
    </button>
    <button
      phx-click={show_modal("game-#{@game.id}-edit-modal")}
      disabled={is_nil(@game.result) && !@bye}
      class="disabled:text-zinc-400 disabled:cursor-not-allowed"
      title="Edit game information"
    >
      <.icon class="-mt-1 ml-2" name="hero-ellipsis-horizontal-circle" />
    </button>
    <a href={~p"/tournaments/#{@game.tournament_id}/games/#{@game}"} title="Go to game page">
      <.icon class="-mt-1 ml-2" name="hero-arrow-top-right-on-square" />
    </a>
    <button
      :if={@signed_in && @swiss}
      phx-click="switch-player-colors"
      phx-value-id={@game.id}
      disabled={!is_nil(@game.result)}
      class="disabled:text-zinc-400 disabled:cursor-not-allowed"
      title="Swap player colors"
    >
      <.icon class="-mt-1 ml-2" name="hero-arrow-path" />
    </button>
    <button
      :if={@signed_in && @swiss}
      phx-click="unpair-players"
      phx-value-id={@game.id}
      disabled={!is_nil(@game.result) && !@bye}
      class="disabled:text-zinc-400 disabled:cursor-not-allowed"
      title="Unpair players"
    >
      <.icon class="-mt-1 ml-2" name="hero-scissors" />
    </button>
    """
  end

  attr(:game_id, :any, default: nil)
  attr(:value, :any)
  attr(:valid, :boolean, default: nil)

  def game_link_input(assigns) do
    ~H"""
    <div phx-feedback-for={"game-#{@game_id}-link"}>
      <.label for={"game-#{@game_id}-link"}>
        Game Link
        <span :if={@valid == false}>
          <.icon class="-mt-1 ml-0.5 bg-rose-400" name="hero-x-circle-mini" />
        </span>
        <span :if={@valid == true}>
          <.icon class="-mt-1 ml-0.5 bg-emerald-700" name="hero-check-circle-mini" />
        </span>
      </.label>
      <input
        type="text"
        name="game_link"
        id={"game-#{@game_id}-link"}
        form={"game-#{@game_id}"}
        value={Phoenix.HTML.Form.normalize_value("text", @value)}
        phx-debounce="blur"
        class={[
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
          "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400",
          @valid != false && "border-zinc-300 focus:border-zinc-400",
          @valid == false && "border-rose-400 focus:border-rose-400"
        ]}
      />
    </div>
    """
  end

  defp fetch_round(round_id) do
    Rounds.get_round_with_matches_and_players!(round_id)
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

  defp ensure_updatable(params, socket) do
    with :ok <- check_result?(params),
         {:ok, nil} <- ensure_playing(socket) do
      :ok
    else
      :skip -> :ok
      {:error, msg} -> {:error, msg}
    end
  end

  defp check_result?(params) do
    if "result" in params["_target"], do: :ok, else: :skip
  end

  defp ensure_playing(socket) do
    case socket.assigns[:round].status do
      :playing -> {:ok, nil}
      _ -> {:error, "Round status is #{socket.assigns[:round].status}"}
    end
  end

  defp fetch_player_with_history(player_id, tournament_id, roster) do
    games = Games.get_games_from_tournament_for_player(tournament_id, player_id, roster)

    case Players.get_player_with_tournament_history(player_id, games) do
      nil -> {:error, "Could not fetch tournament history for player"}
      player -> {:ok, player}
    end
  end

  defp valid_link?(nil), do: nil

  defp valid_link?(link) do
    with {:ok, provider} <- PgnProvider.find_provider(link),
         {:ok, _link} <- provider.extract_id(link) do
      true
    else
      {:error, _} -> false
    end
  end
end
