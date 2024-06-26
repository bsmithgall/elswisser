defmodule ElswisserWeb.Router do
  use ElswisserWeb, :router

  import ElswisserWeb.Accounts.UserAuth
  import ElswisserWeb.Plugs.SlackEnabled

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {ElswisserWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:fetch_current_user)
    plug(:slack_enabled)
  end

  ## "Admin" (login-only) routes

  scope "/", ElswisserWeb do
    pipe_through(:browser)
    pipe_through(:require_authenticated_user)

    resources "/tournaments", Tournaments.TournamentController, except: [:index, :show] do
      resources("/rounds", RoundController, only: [:create, :update])

      scope("/rounds") do
        post("/:id/finalize", RoundController, :finalize)
        get("/:id/pairings", RoundController, :pairings)
      end

      resources("/games", GameController, only: [:edit, :update])
    end

    scope("/tournaments") do
      put("/:id/roster", Tournaments.RosterController, :update)
      patch("/:id/roster", Tournaments.RosterController, :update)
    end

    resources("/players", PlayerController, except: [:index, :show])
  end

  ## Public (view) routes

  scope "/", ElswisserWeb do
    pipe_through(:browser)

    get("/", PageController, :home)

    resources "/tournaments", Tournaments.TournamentController, only: [:index, :show] do
      resources("/rounds", RoundController, only: [:show])

      resources("/games", GameController, only: [:show])
    end

    scope("/tournaments") do
      get("/:id/crosstable", Tournaments.StatsController, :crosstable, as: :crosstable)
      get("/:id/scores", Tournaments.StatsController, :scores, as: :scores)
      get("/:id/stats", Tournaments.StatsController, :stats, as: :stats)
      get("/:id/roster", Tournaments.RosterController, :index)
      get("/:id/games", Tournaments.GamesController, :index)
      get("/:id/current-games", Tournaments.GamesController, :current, as: :current)
    end

    resources("/players", PlayerController, only: [:index, :show])

    live "/live-board", Elchesser.Live
    live "/play-computer", Elchesser.Computer
  end

  ## Authentication routes

  scope "/accounts", ElswisserWeb.Accounts, as: :accounts do
    pipe_through([:browser, :redirect_if_user_is_authenticated])

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{ElswisserWeb.Accounts.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/log_in", UserLoginLive, :new
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/accounts", ElswisserWeb.Accounts, as: :accounts do
    pipe_through(:browser)

    delete "/users/log_out", UserSessionController, :delete
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:elswisser, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through(:browser)

      live_dashboard("/dashboard", metrics: ElswisserWeb.Telemetry)
      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end
end
