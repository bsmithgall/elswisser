defmodule ElswisserWeb.Brackets.SingleElimination do
  alias Elswisser.Matches.Match
  import ElswisserWeb.ChessComponents
  use Phoenix.Component

  attr(:length, :integer, required: true)
  attr(:rounds, :list, required: true)
  attr(:size, :integer, required: true)

  def bracket(assigns) do
    ~H"""
    <div class="els__bracket flex text-sm text-zinc-700 overflow-x-auto">
      <%= for idx <- 1..@length do %>
        <.bracket_round round={Enum.at(@rounds, idx - 1)} number={idx} size={@size} />
      <% end %>
    </div>
    """
  end

  attr(:round, Elswisser.Rounds.Round, default: nil)
  attr(:number, :integer, required: true)
  attr(:size, :integer, required: true)

  def bracket_round(%{round: nil} = assigns) do
    ~H"""
    <div class="els__round flex flex-col grow">
      <%= for _ <- 1..match_count(@number, @size) do %>
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
      <div class="els__match-content border border-zinc-400 relative py-1 px-2 rounded-md flex flex-row gap-1">
        <.game_result game={Match.first_game_or_nil(@match)} ratings={false} />
      </div>
    </div>
    """
  end

  defp match_count(round_number, players) do
    div(players, Math.pow(2, round_number))
  end
end
