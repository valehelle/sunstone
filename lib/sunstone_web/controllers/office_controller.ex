defmodule SunstoneWeb.OfficeController do
  use SunstoneWeb, :controller
  alias Sunstone.Chats
  alias Sunstone.Chats.Office

  def index(conn, _) do
    user = Guardian.Plug.current_resource(conn)
  
    render conn, "index.html", user: user
  end
  def new(conn, _params)  do
    user = Guardian.Plug.current_resource(conn)
    changeset = Office.changeset(%Office{}, %{}, user)
    render conn, "new.html", changeset: changeset
  end

  def create(conn, %{"office" => office_params})  do
    user = Guardian.Plug.current_resource(conn)
    Chats.create_office(office_params, user)
    redirect(conn, to: Routes.office_path(conn, :index))
  end

end
