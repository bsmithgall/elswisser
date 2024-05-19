defmodule ElswisserWeb.Brackets.DoubleElimination do
  require Integer
  use Phoenix.Component
  use Phoenix.VerifiedRoutes, endpoint: ElswisserWeb.Endpoint, router: ElswisserWeb.Router

  import ElswisserWeb.CoreComponents
  import ElswisserWeb.Brackets.Shared

  attr(:tournament, Elswisser.Tournaments.Tournament, required: true)

  def bracket(assigns) do
    assigns = assigns |> assign(Enum.group_by(assigns.tournament.rounds, & &1.type))

    ~H"""
    <div id="bracket-boundary">
      <.header class="mt-4">Winners Bracket</.header>
      <div class="els__bracket my-4 flex text-sm text-zinc-700 overflow-x-auto h-full">
        <%= for rnd <- @winner do %>
          <.bracket_round round={rnd} />
        <% end %>
      </div>

      <hr />

      <.header class="mt-4">Losers Bracket</.header>
      <div class="els__bracket my-4 flex text-sm text-zinc-700 overflow-x-auto h-full pb-6">
        <%= for rnd <- @loser do %>
          <.lower_round round={rnd} />
        <% end %>
      </div>

      <hr />

      <.header class="mt-4">Championship</.header>
      <div class="els__bracket my-4 flex">
        <.bracket_round round={hd(@championship)} grow={false} />
      </div>
    </div>
    """
  end

  attr(:round, Elswisser.Rounds.Round, default: nil)

  def lower_round(assigns) do
    assigns =
      assigns |> assign(:sorted, Enum.sort_by(assigns.round.matches, & &1.display_order))

    ~H"""
    <div class="els__lower_round flex flex-col grow">
      <.section_title class="text-center">
        <.link
          href={~p"/tournaments/#{@round.tournament_id}/rounds/#{@round}"}
          class="hover:underline"
        >
          <%= @round.display_name %>
        </.link>
      </.section_title>
      <%= for match <- @sorted do %>
        <.match match={match} />
      <% end %>
    </div>
    """
  end
end
