defmodule ElswisserWeb.RoundLive.Pairing do
  use ElswisserWeb, :live_view
  import ElswisserWeb.GameHTML, only: [result: 1]

  alias Elswisser.Players
  alias Elswisser.Games

  embed_templates("pairing_html/*")

  @impl true
  def mount(_params, session, socket) do
    {:ok,
     socket
     |> switch_color()
     |> assign(:round_id, session["round_id"])
     |> assign(:roster, session["tournament"].players)
     |> assign(:tournament_id, session["tournament_id"])
     |> assign(:players, fetch_unpaired_players(session["tournament_id"], session["round_id"])),
     layout: false}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.flash_group flash={@flash} />
    <div class="mt-8 flex">
      <div class="w-2/5 box-border border-r border-r-zinc-400 pr-4 mr-4">
        <.section_title class="text-xs uppercase mb-4">Select players for pairing</.section_title>
        <.select_player
          players={@players}
          color={@color}
          white_id={assigns[:white] && assigns[:white].id}
          black_id={assigns[:black] && assigns[:black].id}
        />
      </div>
      <div class="w-3/5">
        <.actions
          white_id={assigns[:white] && assigns[:white].id}
          black_id={assigns[:black] && assigns[:black].id}
        />
        <div class="flex">
          <div class="w-1/2 mt-4 mr-4 p-4 pr-6 bg-zinc-50 rounded-md border border-solid border-zinc-400">
            <.section_title class="text-xs text-center uppercase mb-4">White</.section_title>
            <.player_card_skeleton :if={is_nil(assigns[:white])} />
            <.player_card :if={assigns[:white]} player={@white} />
          </div>
          <div class="w-1/2 mt-4 p-4 bg-indigo-200 rounded-md border-solid border border-zinc-400">
            <.section_title class="text-xs text-center uppercase mb-4">Black</.section_title>
            <.player_card_skeleton :if={is_nil(assigns[:black])} />
            <.player_card :if={assigns[:black]} player={@black} />
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("select-player", params, socket) do
    case fetch_player_with_history(
           params["player-id"],
           socket.assigns[:tournament_id],
           socket.assigns[:roster]
         ) do
      nil -> {:error, socket}
      player -> {:noreply, socket |> switch_color() |> assign(socket.assigns[:color], player)}
    end
  end

  @impl true
  def handle_event("switch-colors", _params, socket) do
    {:noreply,
     socket |> assign(:white, socket.assigns[:black]) |> assign(:black, socket.assigns[:white])}
  end

  @impl true
  def handle_event("do-match", params, socket) do
    case Games.create_game(%{
           white_id: params["white-id"],
           black_id: params["black-id"],
           tournament_id: socket.assigns[:tournament_id],
           round_id: socket.assigns[:round_id]
         }) do
      {:ok, game} ->
        {:noreply,
         socket
         |> put_flash(:info, "Successfully paired players!")
         |> switch_color()
         |> assign(:players, filter_just_matched(socket.assigns[:players], game))
         |> assign(:white, nil)
         |> assign(:black, nil)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, socket |> put_flash(:error, "Could not create Game: #{changeset}")}
    end
  end

  attr(:players, :list, required: true)
  attr(:color, :atom, required: true, values: [:white, :black])
  attr(:white_id, :integer, default: nil, required: false)
  attr(:black_id, :integer, default: nil, required: false)

  def select_player(assigns) do
    ~H"""
    <table class="table-auto w-full">
      <thead>
        <tr class="border-b text-sm leading-6 text-left">
          <th></th>
          <th>Player</th>
        </tr>
      </thead>
      <tbody class="text-sm leading-6">
        <%= for player <- @players do %>
          <.player_row
            id={player.id}
            name={player.name}
            color={@color}
            disabled={player.id == @white_id or player.id == @black_id}
          />
        <% end %>
      </tbody>
    </table>
    """
  end

  attr(:id, :integer, required: true)
  attr(:disabled, :boolean, required: true)
  attr(:name, :string, required: true)
  attr(:color, :atom, required: true, values: [:white, :black])

  def player_row(assigns)

  attr(:white_id, :integer, default: nil, required: false)
  attr(:black_id, :integer, default: nil, required: false)
  attr(:disabled, :boolean, default: false)

  def actions(assigns) do
    assigns = assign(assigns, :disabled, is_nil(assigns[:white_id]) || is_nil(assigns[:black_id]))

    ~H"""
    <div class="text-center">
      <.light_button disabled={@disabled} phx-click="switch-colors">
        <.icon name="hero-arrows-right-left-mini" class="-mt-1" /> Swap colors
      </.light_button>
      <.success_button
        disabled={@disabled}
        phx-click="do-match"
        phx-value-white-id={@white_id}
        phx-value-black-id={@black_id}
      >
        <.icon name="hero-check-mini" class="-mt-1" /> Match players
      </.success_button>
    </div>
    """
  end

  def player_card_skeleton(assigns)

  attr(:player, :map, required: true)

  def player_card(assigns) do
    all_games = Players.Player.all_games(assigns[:player])

    assigns =
      assign(assigns, %{
        games: all_games,
        score: Elswisser.Scores.raw_score_for_player(all_games, assigns[:player].id)
      })

    ~H"""
    <div class="w-full pb-8">
      <.section_title><%= @player.name %></.section_title>

      <.condensed_list>
        <:item title="Score"><%= @score %></:item>
        <:item title="Rating"><%= @player.rating %></:item>
        <:item title="# White"><%= length(@player.white_games) %></:item>
        <:item title="# Black"><%= length(@player.black_games) %></:item>
      </.condensed_list>
    </div>
    <div class="w-full">
      <.section_title class="mb-4">Tournament History</.section_title>
      <ol reversed class="list-decimal list-inside text-sm">
        <%= for game <- @games do %>
          <li class="pb-1">
            <.link href={~p"/tournaments/#{game.tournament_id}/games/#{game.id}"}>
              <.result
                white={game.white.name}
                black={game.black.name}
                result={game.result}
                class="underline text-cyan-600 inline"
              />
            </.link>
          </li>
        <% end %>
      </ol>
    </div>
    """
  end

  defp switch_color(socket) do
    case socket.assigns[:color] do
      :white -> assign(socket, :color, :black)
      _ -> assign(socket, :color, :white)
    end
  end

  defp fetch_unpaired_players(tournament_id, round_id) do
    Players.get_unpaired_players(tournament_id, round_id)
  end

  defp fetch_player_with_history(player_id, tournament_id, roster) do
    games = Games.get_games_from_tournament_for_player(tournament_id, player_id, roster)

    Players.get_player_with_tournament_history(player_id, games)
  end

  defp filter_just_matched(pairings, _game) when is_nil(pairings), do: []
  defp filter_just_matched(pairings, game) when is_nil(game), do: pairings

  defp filter_just_matched(pairings, game) when is_list(pairings) do
    Enum.filter(pairings, fn p ->
      p.id != game.white_id && p.id != game.black_id
    end)
  end
end
