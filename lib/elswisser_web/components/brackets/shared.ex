defmodule ElswisserWeb.Brackets.Shared do
  import ElswisserWeb.ChessComponents
  use Phoenix.Component

  alias Elswisser.Matches.Match

  attr(:round, Elswisser.Rounds.Round, default: nil)
  attr(:match_count, :integer)

  def bracket_round(%{round: nil} = assigns) do
    ~H"""
    <div class="els__round flex flex-col grow">
      <%= for _ <- 1..@match_count do %>
        <.match />
      <% end %>
    </div>
    """
  end

  def bracket_round(assigns) do
    assigns =
      assigns |> assign(:sorted, Enum.sort_by(assigns.round.matches, & &1.display_order))

    ~H"""
    <div class="els__round flex flex-col grow">
      <%= for match <- @sorted do %>
        <.match match={match} />
      <% end %>
    </div>
    """
  end

  attr(:match, Elswisser.Matches.Match, default: nil)

  def match(assigns) do
    ~H"""
    <div class="els__match flex flex-col justify-center grow relative py-4 mx-2 min-w-fit w-64">
      <div class="els__match-content border border-zinc-400 relative py-1 px-2 rounded-md">
        <.game_result game={Match.first_game_or_nil(@match)} ratings={false} show_seeds={true} />
      </div>
    </div>
    """
  end
end
