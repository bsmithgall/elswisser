defmodule ElswisserWeb.Brackets.Shared do
  import ElswisserWeb.ChessComponents
  import ElswisserWeb.CoreComponents
  use Phoenix.Component
  use Phoenix.VerifiedRoutes, endpoint: ElswisserWeb.Endpoint, router: ElswisserWeb.Router

  alias Elswisser.Matches.Match

  attr(:round, Elswisser.Rounds.Round, default: nil)
  attr(:round_number, :integer)
  attr(:match_count, :integer)
  attr(:class, :string, default: "els__round")
  attr(:grow, :boolean, default: true)

  def bracket_round(%{round: nil} = assigns) do
    ~H"""
    <div class={[@class, "flex flex-col", @grow && "grow"]}>
      <.section_title :if={@round_number} class="text-center">
        Round <%= @round_number %>
      </.section_title>
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
    <div class={[@class, "flex flex-col", @grow && "grow"]}>
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
