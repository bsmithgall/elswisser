defmodule Elswisser.Slack do
  require IEx
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
         {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
           HTTPoison.post(@post_message, encoded, [
             {"Content-Type", "application/json; charset=utf-8"},
             {"Authorization", "Bearer #{token}"}
           ]) do
      {:ok, body}
    else
      err -> {:error, err}
    end
  end

  defp encode({:text, msg}, channel), do: Jason.encode(%{text: msg, channel: channel})
  defp encode({:blocks, msg}, channel), do: Jason.encode(%{blocks: msg, channel: channel})
  defp encode(msg, channel) when is_binary(msg), do: encode({:text, msg}, channel)
end
