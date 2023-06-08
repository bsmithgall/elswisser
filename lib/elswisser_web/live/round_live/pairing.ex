defmodule ElswisserWeb.RoundLive.Pairing do
  use ElswisserWeb, :live_view

  alias Elswisser.Players
  alias Elswisser.Games

  embed_templates("pairing_html/*")

  @impl true
  def mount(_params, session, socket) do
    {:ok,
     socket
     |> switch_color()
     |> assign(:round_id, session["round_id"])
     |> assign(:tournament_id, session["tournament_id"])
     |> assign(:white, Players.get_player_with_tournament_history(4, session["tournament_id"]))
     |> assign(:black, Players.get_player_with_tournament_history(5, session["tournament_id"]))
     |> assign(:players, fetch_unpaired_players(session["tournament_id"], session["round_id"])),
     layout: false}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.flash_group flash={@flash} />
    <div class="mt-8 flex">
      <div class="w-2/5 box-border border-r border-r-zinc-400 pr-4 mr-4">
        <h3>Select players for pairing</h3>
        <.select_player
          players={@players}
          color={@color}
          white={assigns[:white]}
          black={assigns[:black]}
        />
      </div>
      <div class="w-3/5">
        <.actions
          white_id={assigns[:white] && assigns[:white].id}
          black_id={assigns[:black] && assigns[:black].id}
        />
        <.player_card :if={assigns[:white]} player={@white} />
        <.player_card :if={assigns[:black]} player={@black} />
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("select-player", params, socket) do
    case Players.get_player_with_tournament_history(
           params["player-id"],
           socket.assigns[:tournament_id]
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
  attr(:white, :map, default: nil, required: false)
  attr(:black, :map, default: nil, required: false)

  def select_player(assigns)

  attr(:white_id, :integer, default: nil, required: false)
  attr(:black_id, :integer, default: nil, required: false)

  def actions(assigns) do
    assigns = assign(assigns, :disabled, is_nil(assigns[:white_id]) || is_nil(assigns[:black_id]))

    ~H"""
    <div class="text-center">
      <.button disabled={@disabled} phx-click="switch-colors">
        Swap colors
      </.button>
      <.button
        disabled={@disabled}
        phx-click="do-match"
        phx-value-white-id={@white_id}
        phx-value-black-id={@black_id}
      >
        Match players
      </.button>
    </div>
    """
  end

  attr(:player, :map, required: true)

  def player_card(assigns) do
    all_games = Players.Player.all_games(assigns[:player])

    assigns =
      assign(assigns, %{
        games: all_games,
        score: Elswisser.Scores.raw_score_for_player(all_games, assigns[:player].id)
      })

    ~H"""
    <div class="w-full flex mt-4">
      <div class="w-3/5 pr-8">
        <%= @player.name %>

        <.condensed_list>
          <:item title="Score"><%= @score %></:item>
          <:item title="Rating"><%= @player.rating %></:item>
          <:item title="White Games"><%= length(@player.white_games) %></:item>
          <:item title="Black Games"><%= length(@player.black_games) %></:item>
        </.condensed_list>
      </div>
      <div class="w-2/5">
        <span>Games</span>
        <ul>
          <%= for game <- @games do %>
            <li>
              <.link href={~p"/tournaments/#{game.tournament_id}/games/#{game.id}"}>
                <%= game.id %>
              </.link>
            </li>
          <% end %>
        </ul>
      </div>
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

  defp filter_just_matched(pairings, _game) when is_nil(pairings), do: []
  defp filter_just_matched(pairings, game) when is_nil(game), do: pairings

  defp filter_just_matched(pairings, game) when is_list(pairings) do
    Enum.filter(pairings, fn p ->
      p.id != game.white_id && p.id != game.black_id
    end)
  end
end
