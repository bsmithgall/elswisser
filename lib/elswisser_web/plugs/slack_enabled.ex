defmodule ElswisserWeb.Plugs.SlackEnabled do
  import Plug.Conn

  @doc """
  Grab whether or not slack is enabled from app config and stick it on the path
  """
  def slack_enabled(%Plug.Conn{} = conn, _) do
    enabled? =
      with %{} = conf <- Application.get_env(:elswisser, :slack),
           true <- Map.get(conf, :enabled) do
        true
      else
        _ -> false
      end

    assign(conn, :slack_enabled, enabled?)
  end
end
