defmodule SunstoneWeb.UserController do
  use SunstoneWeb, :controller
  alias Sunstone.Accounts
  alias Sunstone.Accounts.User
  alias Sunstone.Accounts.Guardian

  def index(conn, _params) do
    render conn, "index.html"
  end

  def register(conn, _params) do
    changeset = User.changeset(%User{})
    render conn, "new.html", changeset: changeset
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} -> 
      conn = Guardian.Plug.sign_in(conn, user)
      redirect(conn, to: Routes.page_path(conn, :index))
      {:error, changeset} -> 
      render conn, "new.html", changeset: changeset
    end
  end
  
  def login(conn, _params) do
    changeset = User.login_changeset(%User{})
    render conn, "login.html", changeset: changeset
  end

  def create_login(conn, %{"user" => user_params}) do
    case Accounts.authenticate_user(user_params) do
      {:ok, user} -> 
        conn = Guardian.Plug.sign_in(conn, user)        
        %{"remember_me" => remember_me}  = user_params
        redirect_to_office(conn, user, remember_me)       
      {:error, changeset} -> 
      render conn, "login.html", changeset: changeset
    end
  end
  def redirect_to_office(conn, user, "true") do
    conn = Guardian.Plug.remember_me(conn, user)
    redirect(conn, to: Routes.page_path(conn, :index))
  end
  def redirect_to_office(conn, user, "false") do
    redirect(conn, to: Routes.page_path(conn, :index))
  end

  def logout(conn, _) do
    conn
    |> Guardian.Plug.sign_out()
    |> Guardian.Plug.clear_remember_me()
    |> redirect(to: Routes.user_path(conn, :login))
  end

  def auth_error(conn, {type, _reason}, _opts) do
    case type do
      :unauthenticated -> redirect(conn, to: Routes.user_path(conn, :login))
    end
  end

  def dashboard(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    
    render conn, "dashboard.html"
  end



end
