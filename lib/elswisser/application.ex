defmodule Elswisser.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      ElswisserWeb.Telemetry,
      # Start the Ecto repository
      Elswisser.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Elswisser.PubSub},
      # Start Finch
      {Finch, name: Elswisser.Finch},
      # Start the Endpoint (http/https)
      ElswisserWeb.Endpoint
      # Start a worker by calling: Elswisser.Worker.start_link(arg)
      # {Elswisser.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Elswisser.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ElswisserWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
