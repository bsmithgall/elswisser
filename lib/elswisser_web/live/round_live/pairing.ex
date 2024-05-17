defmodule ElswisserWeb.RoundLive.Pairing do
  use ElswisserWeb, :live_view

  alias Elswisser.{Pairings, Players, Rounds, Scores, Games, Matches}
  alias Elswisser.Pairings.Bye
  alias Elswisser.Scores.Score

  embed_templates("pairing_html/*")

  @impl true
  def mount(_params, session, socket) do
    {:ok,
     socket
     |> set_white()
     |> assign(:round_id, session["round_id"])
     |> assign(:round_number, session["round_number"])
     |> assign(:roster, session["roster"])
     |> assign(:tournament_id, session["tournament_id"])
     |> assign(:players, fetch_unpaired_players(session["tournament_id"], session["round_id"]))
     |> assign(:next_board, 1), layout: false}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.flash id="pairing-success-flash" kind={:info} title="Success!" flash={@flash} />
    <.flash id="pairing-error-flash" kind={:error} title="Error!" flash={@flash} />
    <div class="mt-8 md:flex">
      <div class="mb-4 md:mb-0 md:w-2/5 md:box-border md:border-r md:border-r-zinc-400 md:pr-4 md:mr-4">
        <.success_button id="es:auto-pair" phx-click="auto-pair-remaining" class="mb-4 w-full">
          Auto-pair remaining players
        </.success_button>
        <.section_title class="text-xs uppercase mb-4">
          or select player for pairing (<%= @color %> pieces)
        </.section_title>
        <.select_player
          players={@players}
          color={@color}
          white_id={assigns[:white] && assigns[:white].id}
          black_id={assigns[:black] && assigns[:black].id}
        />
      </div>
      <div class="mt-4 md:mt-0 md:w-3/5">
        <.actions
          white_id={assigns[:white] && assigns[:white].id}
          black_id={assigns[:black] && assigns[:black].id}
        />
        <.matchup white={assigns[:white]} black={assigns[:black]} remove />
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("select-player", %{"player-id" => "-1"}, socket) do
    {:noreply, socket |> switch_color() |> assign(socket.assigns[:color], Bye.bye_player())}
  end

  @impl true
  def handle_event("select-player", %{"player-id" => player_id}, socket) do
    case fetch_player_with_history(
           player_id,
           socket.assigns[:tournament_id],
           socket.assigns[:roster]
         ) do
      nil -> {:error, socket}
      player -> {:noreply, socket |> switch_color() |> assign(socket.assigns[:color], player)}
    end
  end

  @impl true
  def handle_event("remove-player", %{"color" => "white"}, socket) do
    {:noreply, socket |> assign(:color, :white) |> assign(:white, nil)}
  end

  @impl true
  def handle_event("remove-player", %{"color" => "black"}, socket) do
    {:noreply, socket |> assign(:color, :black) |> assign(:black, nil)}
  end

  @impl true
  def handle_event("switch-colors", _params, socket) do
    {:noreply,
     socket |> assign(:white, socket.assigns[:black]) |> assign(:black, socket.assigns[:white])}
  end

  @impl true
  def handle_event("do-match", %{"white-id" => white_id, "black-id" => black_id}, socket) do
    case Matches.create_match_from_game(
           to_game_params(socket, white_id, black_id),
           socket.assigns[:next_board]
         ) do
      {:ok, %{game: game, match: _match}} ->
        remaining = filter_just_matched(socket.assigns[:players], game)

        if length(remaining) == 0 do
          handle_pairing_finished(socket)
        else
          {:noreply,
           socket
           |> put_flash(:info, "Successfully paired players!")
           |> set_white()
           |> assign(:players, remaining)
           |> assign(:white, nil)
           |> assign(:black, nil)}
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, socket |> put_flash(:error, "Could not create Game: #{changeset}")}
    end
  end

  @impl true
  def handle_event("auto-pair-remaining", _params, socket) do
    remaining_ids = socket.assigns[:players] |> Enum.map(& &1.id)
    all_games = Games.get_games_with_round_number_for_tournament(socket.assigns[:tournament_id])

    remaining =
      Scores.calculate(all_games)
      |> Scores.with_players(socket.assigns[:roster])
      |> Map.filter(fn {player_id, _score} -> Enum.member?(remaining_ids, player_id) end)

    with {assigned_bye, eligibles} <- Pairings.assign_bye_player(Map.values(remaining)),
         sorted_scores <- Scores.sort(eligibles),
         {:ok, pairings} <- Pairings.pair(sorted_scores),
         tentative_assignments <- Pairings.assign_colors(pairings, remaining),
         assignments <-
           Pairings.finalize_colors(tentative_assignments, socket.assigns[:round_number]),
         game_params <- to_game_params(socket, assignments),
         ordered <-
           order_params(game_params, sorted_scores) ++ bye_game_params(socket, assigned_bye),
         {:ok, _games} <- Matches.create_matches_from_games(ordered) do
      handle_pairing_finished(socket)
    else
      {:error, _reason} -> {:error, socket}
    end
  end

  attr(:players, :list, required: true)
  attr(:color, :atom, required: true, values: [:white, :black])
  attr(:white_id, :integer, default: nil, required: false)
  attr(:black_id, :integer, default: nil, required: false)

  def select_player(assigns) do
    ~H"""
    <table class="table-fixed w-full">
      <thead>
        <tr class="border-b text-sm leading-6 text-left">
          <th class="w-10"></th>
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
        <tr class="border-4"></tr>
        <.player_row
          id={Bye.bye_player().id}
          name={Bye.bye_player().name}
          color={@color}
          disabled={Bye.bye_player_id() == @white_id or Bye.bye_player_id() == @black_id}
        />
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
    <div class="flex flex-row justify-center gap-2 mb-4">
      <.light_button disabled={@disabled} phx-click="switch-colors" class="w-36 px-1">
        <.icon name="hero-arrows-right-left-mini" class="-mt-1" /> Swap colors
      </.light_button>
      <.success_button
        class="w-36 px-1"
        disabled={@disabled}
        phx-click="do-match"
        phx-value-white-id={@white_id}
        phx-value-black-id={@black_id}
      >
        <.icon name="hero-check-mini" class="-mt-1 pr-1" />Match players
      </.success_button>
    </div>
    """
  end

  defp handle_pairing_finished(socket) do
    case Rounds.set_playing(socket.assigns[:round_id]) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "All pairings finished!")
         |> redirect(
           to:
             ~p"/tournaments/#{socket.assigns[:tournament_id]}/rounds/#{socket.assigns[:round_id]}"
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, socket |> put_flash(:error, "Could not start playing Round: #{changeset}")}
    end
  end

  # Using the sorted scores, order the boards so that the top players are on the
  # top boards.
  defp order_params(game_params, scores) do
    in_order =
      scores
      |> Enum.with_index()
      |> Enum.reduce(%{}, fn {score, idx}, acc -> Map.put(acc, score.player_id, idx) end)

    Enum.sort(game_params, fn g1, g2 ->
      Enum.min([Map.get(in_order, g1.white_id), Map.get(in_order, g1.black_id)]) <=
        Enum.min([Map.get(in_order, g2.white_id), Map.get(in_order, g2.black_id)])
    end)
  end

  defp switch_color(socket) do
    case socket.assigns[:color] do
      :white -> assign(socket, :color, :black)
      _ -> assign(socket, :color, :white)
    end
  end

  defp set_white(socket) do
    assign(socket, :color, :white)
  end

  defp fetch_unpaired_players(tournament_id, round_id) do
    Rounds.get_unpaired_players(round_id, tournament_id)
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

  def bye_game_params(_socket, :none), do: []

  def bye_game_params(socket, %Score{} = assigned_bye),
    do: [
      %{
        white_id: assigned_bye.player_id,
        white_rating:
          Enum.find(socket.assigns[:roster], &(&1.id == assigned_bye.player_id)).rating,
        black_id: -1,
        black_rating: nil,
        tournament_id: socket.assigns[:tournament_id],
        round_id: socket.assigns[:round_id]
      }
    ]

  def to_game_params(socket, pairings) when is_list(pairings) do
    Enum.map(pairings, fn {white_id, black_id} -> to_game_params(socket, white_id, black_id) end)
  end

  defp to_game_params(socket, white_id, black_id)
       when is_binary(white_id) and is_binary(black_id) do
    to_game_params(socket, String.to_integer(white_id), String.to_integer(black_id))
  end

  defp to_game_params(socket, white_id, black_id) do
    %{
      white_id: white_id,
      white_rating: find_player(socket, white_id).rating,
      black_id: black_id,
      black_rating: find_player(socket, black_id).rating,
      tournament_id: socket.assigns[:tournament_id],
      round_id: socket.assigns[:round_id]
    }
  end

  defp find_player(socket, id) when is_binary(id) do
    find_player(socket, String.to_integer(id))
  end

  defp find_player(_, -1), do: Bye.bye_player()

  defp find_player(socket, id) when is_number(id) do
    Enum.find(socket.assigns[:roster], &(&1.id == id))
  end
end
