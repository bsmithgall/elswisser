defmodule ElswisserWeb.Brackets.DoubleElimination do
  require Integer
  use Phoenix.Component

  import ElswisserWeb.CoreComponents
  import ElswisserWeb.Brackets.Shared

  attr(:length, :integer, required: true)
  attr(:rounds, :list, required: true)
  attr(:size, :integer, required: true)

  def bracket(assigns) do
    {winners, losers} = Enum.split_with(1..assigns.length, &Integer.is_odd/1)

    assigns =
      assigns
      |> assign(
        :winners,
        winners
        |> Enum.with_index()
        |> Enum.take_while(fn {_, idx} -> idx + 1 != length(winners) end)
      )
      |> assign(:losers, losers |> Enum.with_index())
      |> assign(:grand_final, {List.last(winners), length(winners) - 1})

    ~H"""
    <.header class="mt-4">Winners Bracket</.header>
    <div class="els__bracket flex text-sm text-zinc-700 overflow-x-auto">
      <%= for {rnd_number, idx} <- @winners do %>
        <.bracket_round
          round={Enum.at(@rounds, rnd_number - 1)}
          match_count={winner_match_count(idx + 1, @size)}
        />
      <% end %>

      <.bracket_round round={Enum.at(@rounds, elem(@grand_final, 1))} match_count={1} />
    </div>

    <hr />

    <.header class="mt-4">Losers Bracket</.header>
    <div class="els__bracket flex text-sm text-zinc-700 overflow-x-auto">
      <%= for {rnd_number, idx} <- @losers do %>
        <.bracket_round
          round={Enum.at(@rounds, rnd_number)}
          match_count={winner_match_count(idx + 1, @size)}
        />
      <% end %>
    </div>
    """
  end

  defp winner_match_count(round_number, player_count) do
    div(player_count, Math.pow(2, round_number))
  end
end
