defmodule ElswisserWeb.Router do
  use ElswisserWeb, :router

  import ElswisserWeb.Accounts.UserAuth

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {ElswisserWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:fetch_current_user)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", ElswisserWeb do
    pipe_through(:browser)

    get("/", PageController, :home)

    resources "/tournaments", TournamentController do
      resources("/rounds", RoundController, only: [:show, :create, :update])

      scope("/rounds") do
        get("/:id/pairings", RoundController, :pairings)
        post("/:id/finalize", RoundController, :finalize)
      end

      resources("/games", GameController, only: [:show, :edit, :update])
    end

    scope("/tournaments") do
      get("/:id/crosstable", TournamentController, :crosstable, as: :crosstable)
      get("/:id/scores", TournamentController, :scores, as: :scores)

      get("/:id/roster", RosterController, :index)
      put("/:id/roster", RosterController, :update)
      patch("/:id/roster", RosterController, :update)
    end

    resources("/players", PlayerController)
  end

  # Other scopes may use custom stacks.
  # scope "/api", ElswisserWeb do
  #   pipe_through :api
  # end

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

  ## Authentication routes

  scope "/accounts", ElswisserWeb.Accounts, as: :accounts do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{ElswisserWeb.Accounts.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/log_in", UserLoginLive, :new
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/accounts", ElswisserWeb.Accounts, as: :accounts do
    delete "/users/log_out", UserSessionController, :delete
  end
end
