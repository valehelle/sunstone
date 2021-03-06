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
    pipe_through [:browser, :auth]
    get "/", PageController, :landing
    get "/register", UserController, :register
    get "/login", UserController, :login
    post "/login", UserController, :create_login
    post "/new", UserController, :create
    post "/logout", UserController, :logout
    get "/contact", PageController, :contact
    get "/request_reset", UserController, :new_reset
    post "/request_reset", UserController, :create_reset
    get "/reset", UserController, :new_reset_password
    post "/reset", UserController, :create_reset_password
    put "/reset", UserController, :create_reset_password
  end


  scope "/", SunstoneWeb do
    pipe_through [:browser, :auth, :ensure_auth]
    get "/office/new", OfficeController, :new
    post "/office/new", OfficeController, :create
    get "/office/invite/:hash_id", InviteController, :new
    post "/office/invite/:hash_id", InviteController, :create
    post "/office/accept/:hash_id", InviteController, :accept
    get "/office/uninvited/:hash_id", OfficeController, :uninvited
    live "/office/:hash_id", PageLive, :index
    get "/office", OfficeController, :index
  
  end

    scope "/", SunstoneWeb do
    pipe_through [:api, :auth, :ensure_auth]
    post "/office/:hash_id/notification", NotificationController, :new
  
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
