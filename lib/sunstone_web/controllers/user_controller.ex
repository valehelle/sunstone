defmodule SunstoneWeb.UserController do
  use SunstoneWeb, :controller
  alias Sunstone.Accounts
  alias Sunstone.Accounts.User
  alias Sunstone.Accounts.Guardian
  alias Sunstone.Accounts.Reset

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
      Accounts.create__social(%{"message" => "Office", "status" => "Available"}, user)
      redirect_to_office(conn, user, "true") 
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
    redirect(conn, to: Routes.office_path(conn, :index))
  end
  def redirect_to_office(conn, user, "false") do
    redirect(conn, to: Routes.office_path(conn, :index))
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

  def home(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    
    render conn, "home.html", user: user
  end

  def encode_id(id) do
    s = Hashids.new([
    salt: Application.get_env(:sunstone, Sunstone.Repo)[:salt],  # using a custom salt helps producing unique cipher text
    min_len: 2,   # minimum length of the cipher text (1 by default)
   ])
    Hashids.encode(s, id)
  end

  def decode_id(hash_id) do
    s = Hashids.new([
    salt: Application.get_env(:sunstone, Sunstone.Repo)[:salt],  # using a custom salt helps producing unique cipher text
    min_len: 2,   # minimum length of the cipher text (1 by default)
   ])
    Hashids.decode!(s, hash_id) |> List.first()
  end




 def send_email(email, uuid) do
      headers = %{
            "Authorization" => "Bearer #{Application.get_env(:sunstone, Sunstone.Repo)[:send_grid_token]}",
            "Content-Type" => "application/json"
          }
          body = %{
            "personalizations" => 
              [
                %{"to" => 
                  [
                    %{"email" => email},
                  ]
                  }
              ],
              "from" => 
              %{
                "email" => "customer_support@inoffice.chat",
              },
              "subject" => "Password Reset",
              "content" => [
                %{"type"=> "text/html", "value" => "<h4>Someone requested to reset the password on your Inoffice account. If you did not request this, please ignore this email.</h4><h4><a href=\"https://www.inoffice.chat/reset?token=#{uuid}\">Reset Password</a></h4>"}
              ]
              
          }
          url = "https://api.sendgrid.com/v3/mail/send"
        HTTPoison.post url, Poison.encode!(body), headers
  end
  def new_reset(conn, _) do
    changeset = Reset.changeset(%Reset{}, %{})
    render conn, "reset.html", changeset: changeset
  end

  def create_reset(conn, %{"reset" => %{"email" => email} = reset_param}) do
    changeset = Reset.changeset(%Reset{}, reset_param)
    case Accounts.get_user_by_email(email) do
      nil -> 
        changeset = Ecto.Changeset.add_error(changeset, :email, "Email not found")
        render conn, "reset.html", changeset: %{changeset | action: :insert}
      user -> 
      uuid = UUID.uuid1()
      params = %{user_id: user.id, token: uuid, has_expired: false}
      Accounts.invalidate_reset(user.id)
      Accounts.create_reset(params)
      send_email(user.email, uuid)
      IO.inspect uuid
      render conn, "reset_request_success.html", changeset: changeset
    end
  end

  def new_reset_password(conn, %{"token" => token}) do
    changeset = Reset.changeset(%Reset{}, %{token: token})
    render conn, "reset_password.html", token: token, changeset: changeset
  end

  def create_reset_password(conn, %{"reset" => %{"token" => token, "password" => password, "retype_password" => retype_password}}) do
    
    case Accounts.get_user_by_token(token) do
      {:ok, user} -> 
        case Accounts.update_user_password(user, %{password: password, retype_password: retype_password}) do
        {:ok, _} ->
          Accounts.invalidate_reset(user.id)
          render conn, "reset_success.html"
        {:error, changeset} -> 
          changeset = Reset.changeset(%Reset{}, %{token: token})
          render conn, "reset_password.html", token: token, changeset: changeset
        end
      _ -> render conn, "reset_error.html"
    end
  end




end
