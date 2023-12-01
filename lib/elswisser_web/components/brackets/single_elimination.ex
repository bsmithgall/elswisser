defmodule ElswisserWeb.Brackets.SingleElimination do
  alias Elswisser.Pairings.BracketPairing
  use Phoenix.Component
  import ElswisserWeb.Brackets.Shared

  attr(:length, :integer, required: true)
  attr(:rounds, :list, required: true)
  attr(:size, :integer, required: true)

  def bracket(assigns) do
    ~H"""
    <div class="els__bracket flex text-sm text-zinc-700 overflow-x-auto">
      <%= for idx <- 1..@length do %>
        <.bracket_round round={Enum.at(@rounds, idx - 1)} match_count={match_count(idx, @size)} />
      <% end %>
    </div>
    """
  end

  defp match_count(round_number, player_count) do
    div(BracketPairing.next_power_of_two(player_count), Math.pow(2, round_number))
  end
end
