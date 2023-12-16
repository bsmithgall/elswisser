defmodule Elswisser.PromEx do
  @moduledoc """
  Be sure to add the following to finish setting up PromEx:

  1. Update your configuration (config.exs, dev.exs, prod.exs, releases.exs, etc) to
     configure the necessary bit of PromEx. Be sure to check out `PromEx.Config` for
     more details regarding configuring PromEx:
     ```
     config :elswisser, Elswisser.PromEx,
       disabled: false,
       manual_metrics_start_delay: :no_delay,
       drop_metrics_groups: [],
       grafana: :disabled,
       metrics_server: :disabled
     ```

  2. Add this module to your application supervision tree. It should be one of the first
     things that is started so that no Telemetry events are missed. For example, if PromEx
     is started after your Repo module, you will miss Ecto's init events and the dashboards
     will be missing some data points:
     ```
     def start(_type, _args) do
       children = [
         Elswisser.PromEx,

         ...
       ]

       ...
     end
     ```

  3. Update your `endpoint.ex` file to expose your metrics (or configure a standalone
     server using the `:metrics_server` config options). Be sure to put this plug before
     your `Plug.Telemetry` entry so that you can avoid having calls to your `/metrics`
     endpoint create their own metrics and logs which can pollute your logs/metrics given
     that Prometheus will scrape at a regular interval and that can get noisy:
     ```
     defmodule ElswisserWeb.Endpoint do
       use Phoenix.Endpoint, otp_app: :elswisser

       ...

       plug PromEx.Plug, prom_ex_module: Elswisser.PromEx

       ...
     end
     ```

  4. Update the list of plugins in the `plugins/0` function return list to reflect your
     application's dependencies. Also update the list of dashboards that are to be uploaded
     to Grafana in the `dashboards/0` function.
  """

  use PromEx, otp_app: :elswisser

  alias PromEx.Plugins

  @impl true
  def plugins do
    [
      # PromEx built in plugins
      Plugins.Application,
      Plugins.Beam,
      {Plugins.Phoenix, router: ElswisserWeb.Router, endpoint: ElswisserWeb.Endpoint},
      Plugins.Ecto
    ]
  end

  @impl true
  def dashboard_assigns do
    config = Application.fetch_env!(:elswisser, :promex_additional)

    [
      datasource_id: config[:datasource_id],
      default_selected_interval: "1m"
    ]
  end

  @impl true
  def dashboards do
    [
      {:prom_ex, "application.json"},
      {:prom_ex, "beam.json"},
      {:prom_ex, "phoenix.json"},
      {:prom_ex, "ecto.json"}
    ]
  end

  def config(true) do
    [
      disabled: false,
      manual_metrics_start_delay: :no_delay,
      drop_metrics_groups: [],
      grafana: Elswisser.PromEx.grafana_config(!is_nil(System.get_env("PROMEX_GRAFANA_ENABLED"))),
      metrics_server: [
        port: String.to_integer(System.get_env("METRICS_SERVER_PORT") || "4021")
      ]
    ]
  end

  def config(false), do: [disabled: true]

  @doc """
  Only to be accessed during application boot
  """
  def grafana_config(true) do
    [
      host: System.get_env("GRAFANA_HOST"),
      auth_token: System.get_env("GRAFANA_AUTH_TOKEN"),
      upload_dashboards_on_start: true,
      folder_name: "Elswisser",
      annotate_app_lifecycle: true
    ]
  end

  def grafana_config(false), do: []
end
