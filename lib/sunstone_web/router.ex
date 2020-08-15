defmodule SunstoneWeb.Router do
  use SunstoneWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {SunstoneWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end


  pipeline :auth do
    plug Sunstone.Accounts.Pipeline
  end

  pipeline :ensure_auth do
    plug Guardian.Plug.EnsureAuthenticated, error_handler: SunstoneWeb.UserController
  end


  scope "/", SunstoneWeb do
    pipe_through :browser
    get "/register", UserController, :register
    get "/login", UserController, :login
    post "/login", UserController, :create_login
    post "/new", UserController, :create
    post "/logout", UserController, :logout
  end


  scope "/", SunstoneWeb do
    pipe_through [:browser, :auth, :ensure_auth]
    live "/live", PageLive, :index

  end


  # Other scopes may use custom stacks.
  # scope "/api", SunstoneWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: SunstoneWeb.Telemetry
    end
  end
end
