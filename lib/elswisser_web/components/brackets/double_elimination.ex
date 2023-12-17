defmodule ElswisserWeb.Brackets.DoubleElimination do
  require Integer
  use Phoenix.Component

  import ElswisserWeb.CoreComponents
  import ElswisserWeb.Brackets.Shared

  attr(:tournament, Elswisser.Tournaments.Tournament, required: true)

  def bracket(assigns) do
    assigns = assigns |> assign(Enum.group_by(assigns.tournament.rounds, & &1.type))

    ~H"""
    <.header class="mt-4">Winners Bracket</.header>
    <div class="my-4 flex text-sm text-zinc-700 overflow-x-auto h-full">
      <%= for rnd <- @winner do %>
        <.bracket_round round={rnd} />
      <% end %>

      <.bracket_round round={hd(@championship)} match_count={1} />
    </div>

    <hr />

    <.header class="mt-4">Losers Bracket</.header>
    <div class="my-4 flex text-sm text-zinc-700 overflow-x-auto h-full">
      <%= for rnd <- @loser do %>
        <.bracket_round round={rnd} />
      <% end %>
    </div>
    """
  end
end
