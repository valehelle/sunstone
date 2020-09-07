defmodule SunstoneWeb.InviteController do
  use SunstoneWeb, :controller
  alias Sunstone.Chats
  alias Sunstone.Chats.Office
  alias Sunstone.Chats.Invite


  def new(conn, %{"hash_id" => hash_id})  do
    office_id = SunstoneWeb.UserController.decode_id(hash_id)
    office = Chats.get_office!(office_id)
    changeset = Invite.changeset(%Invite{}, %{}, office)

    render conn, "new.html", changeset: changeset, hash_id: hash_id
  end

  def create(conn, %{"invite" => %{"email" => email} = invite,"hash_id" => hash_id})  do
    office_id = SunstoneWeb.UserController.decode_id(hash_id)
    office = Chats.get_office!(office_id)
    case Chats.get_invite_from_email!(email) do
      nil ->
        Chats.create_invite(invite, office)
        render conn, "invite.html", email: email, hash_id: hash_id
      email -> 
        changeset = Invite.changeset(%Invite{}, invite, office)
        {_, changeset} = Ecto.Changeset.add_error(changeset, :email, "User have already been invited")  |> Ecto.Changeset.apply_action(:update)
        render conn, "new.html", changeset: changeset, hash_id: hash_id
    end
  end

  def accept(conn, %{"hash_id" => hash_id})  do
    user = Guardian.Plug.current_resource(conn)
    office_id = SunstoneWeb.UserController.decode_id(hash_id)
    office = Chats.get_office!(office_id)
    case Chats.get_invite_from_email!(user.email) do
      nil ->
        redirect(conn, to: Routes.office_path(conn, :index))
      invite -> 
        Chats.add_user_to_office(office, user, invite)
        redirect(conn, to: Routes.office_path(conn, :index))
    end
  end

end
