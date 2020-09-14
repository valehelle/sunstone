defmodule SunstoneWeb.OfficeController do
  use SunstoneWeb, :controller
  alias Sunstone.Chats
  alias Sunstone.Chats.Office
  alias Sunstone.Chats.Invite

  def index(conn, _) do
    user = Guardian.Plug.current_resource(conn)
    invites = Chats.list_invites_from_email(user.email)
    changeset = Office.changeset(%Office{}, %{}, user)
    render conn, "index.html", changeset: changeset, user: user, invites: invites
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

  def invite(conn, %{"hash_id" => hash_id})  do
    changeset = Invite.changeset(%Invite{}, %{})

    render conn, "invite.html", changeset: changeset
  end

  def uninvited(conn, %{"hash_id" => hash_id})  do
    office_id = SunstoneWeb.UserController.decode_id(hash_id)
    office = Chats.get_office!(office_id)
    render conn, "uninvited.html", office: office
  end



end
