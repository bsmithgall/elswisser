defmodule Elswisser.Slack do
  @post_message "https://slack.com/api/chat.postMessage"

  def send(msg) do
    case Application.fetch_env(:elswisser, :slack) do
      :error ->
        {:error, "Could not fetch Slack configuration"}

      {:ok, %{enabled: false}} ->
        {:error, "Slack integration disabled. Make sure SLACK_TOKEN is set."}

      {:ok, %{enabled: true, channel: channel, token: token}} ->
        send_to_slack(msg, channel, token)
    end
  end

  defp send_to_slack(msg, channel, token) do
    with {:ok, encoded} <- encode(msg, channel),
         {:ok, %Req.Response{status: 200, body: body}} <-
           Req.post(
             Req.new(
               url: @post_message,
               headers: [
                 {"content-type", "application/json; charset=utf-8"},
                 {"authorization", "Bearer #{token}"}
               ]
             ),
             body: encoded
           ) do
      {:ok, body}
    else
      err -> {:error, err}
    end
  end

  defp encode({:text, msg}, channel), do: Jason.encode(%{text: msg, channel: channel})
  defp encode({:blocks, msg}, channel), do: Jason.encode(%{blocks: msg, channel: channel})
  defp encode(msg, channel) when is_binary(msg), do: encode({:text, msg}, channel)
end
