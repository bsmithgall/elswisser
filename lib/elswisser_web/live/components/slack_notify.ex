defmodule ElswisserWeb.LiveComponents.SlackNotify do
  import ElswisserWeb.CoreComponents, only: [button: 1, flash_group: 1]
  use ElswisserWeb, :live_view

  alias Elswisser.Matches
  alias Elswisser.Players.Player

  @impl true
  def mount(
        _params,
        %{"tournament_id" => tournament_id, "type" => type, "tournament_name" => tournament_name},
        socket
      ) do
    {:ok,
     socket
     |> assign(:tournament_id, tournament_id)
     |> assign(:type, type)
     |> assign(:tournament_name, tournament_name), layout: false}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.flash_group flash={@flash} include_disconnected={false} />
    <.button phx-click="notify" class="w-full md:w-auto">Notify Participants</.button>
    """
  end

  @impl true
  def handle_event("notify", _params, socket) do
    Task.async(fn ->
      make_slack_blocks(
        socket.assigns.type,
        socket.assigns.tournament_id,
        socket.assigns.tournament_name
      )
      |> Elswisser.Slack.send()
    end)
    |> Task.await()
    |> then(fn {status, body} ->
      case status do
        :ok -> {:noreply, socket |> put_flash(:info, "Notifications sent!")}
        :error -> {:noreply, socket |> put_flash(:error, "Something went wrong: #{body}")}
      end
    end)
  end

  defp make_slack_blocks(:current, tournament_id, tournament_name) do
    Matches.get_active_matches(tournament_id, :mini)
    |> Enum.group_by(& &1.round_display_name)
    |> Enum.flat_map(&to_slack_section/1)
    |> then(fn sections ->
      {:blocks,
       [
         %{
           type: "header",
           text: %{type: "plain_text", text: "Awaiting matches for #{tournament_name}"}
         }
         | sections
       ]}
    end)
  end

  defp to_slack_section({round_name, matches}) do
    [
      %{type: "section", text: %{text: "*Round: #{round_name}*", type: "mrkdwn"}},
      %{
        type: "section",
        text: %{
          text:
            matches
            |> Enum.map(&"• #{render_player(&1.white)} vs #{render_player(&1.black)}")
            |> Enum.join("\n"),
          type: "mrkdwn"
        }
      }
    ]
  end

  defp render_player(%Player.Mini{slack_id: nil, name: name}), do: name
  defp render_player(%Player.Mini{slack_id: slack_id}), do: "<@#{slack_id}>"
end
