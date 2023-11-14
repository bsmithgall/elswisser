defmodule ElswisserWeb.Brackets.SingleElimination do
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
      <%= for _ <- 1..game_count(@number, @size) do %>
        <.match />
      <% end %>
    </div>
    """
  end

  def bracket_round(assigns) do
    ~H"""
    <div class="els__round flex flex-col grow">
      <%= for game <- @round.games do %>
        <.match game={game} />
      <% end %>
    </div>
    """
  end

  attr(:game, Elswisser.Games.Game, default: nil)

  def match(assigns) do
    ~H"""
    <div class="els__match flex flex-col justify-center grow relative py-4 mx-2 min-w-fit w-64">
      <div class="els__match-content border border-zinc-400 relative py-1 px-2 rounded-md">
        <.game_result game={@game} ratings={false} />
      </div>
    </div>
    """
  end

  defp game_count(round_number, players) do
    div(players, Math.pow(2, round_number))
  end
end
