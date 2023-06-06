defmodule ElswisserWeb.RoundLive.Round do
  use ElswisserWeb, :live_view

  alias Elswisser.Games
  alias Elswisser.Rounds

  @impl true
  def mount(_params, session, socket) do
    {:ok, socket |> assign(:round, fetch_games(session["round_id"])), layout: false}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%= for game <- @round.games do %>
      <form id={"game-#{game.id}"} phx-change="save-result" />
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
      <tbody class="relative divide-y divide-zinc-100 border-t border-zinc-200
    text-sm leading-6 text-zinc-700">
        <%= for game <- @round.games do %>
          <input type="hidden" name="id" value={game.id} form={"game-#{game.id}"} />
          <tr class="border-zinc-200 border-b group hover:bg-zinc-50">
            <td>
              <span class="w-6 inline-block">
                <.icon :if={game.result == 1} name="hero-trophy" />
                <.icon :if={game.result == 0} name="hero-scale" />
              </span>
              <%= game.white.name %>
            </td>
            <td>
              <span class="w-6 inline-block">
                <.icon :if={game.result == -1} name="hero-trophy" />
                <.icon :if={game.result == 0} name="hero-scale" />
              </span>
              <%= game.black.name %>
            </td>
            <td>
              <div class="-mt-1">
                <.input
                  id={"game-#{game.id}-result"}
                  name="result"
                  type="select"
                  options={["White won": "1", "Black won": -1, Draw: 0]}
                  value={game.result}
                  phx-value-id={game.id}
                  form={"game-#{game.id}"}
                />
              </div>
            </td>
            <td></td>
          </tr>
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
        {:noreply, socket |> assign(:round, fetch_games(game.round_id))}

      {:error, %Ecto.Changeset{} = _changeset} ->
        {:error, socket}
    end
  end

  defp fetch_games(round_id) do
    Rounds.get_round_with_games!(round_id)
  end
end
