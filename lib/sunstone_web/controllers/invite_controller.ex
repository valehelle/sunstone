defmodule SunstoneWeb.InviteController do
  use SunstoneWeb, :controller
  alias Sunstone.Chats
  alias Sunstone.Chats.Office
  alias Sunstone.Chats.Invite

  def new(conn, %{"hash_id" => hash_id})  do
    office_id = SunstoneWeb.UserController.decode_id(hash_id)
    office = Chats.get_office!(office_id)
    invites = Chats.list_invites_from_office(office)
    changeset = Invite.changeset(%Invite{}, %{}, office)

    render conn, "new.html", changeset: changeset, hash_id: hash_id, office: office, invites: invites
  end

  def create(conn, %{"invite" => %{"email" => email} = invite,"hash_id" => hash_id})  do
    office_id = SunstoneWeb.UserController.decode_id(hash_id)
    office = Chats.get_office!(office_id)
    emails = String.replace(email, " ", "") |> String.split(",");
    Enum.each emails, fn(email) ->
      case Chats.get_invite_from_email!(email, office) do
        nil ->
          invite = %{"email" => email}
          Chats.create_invite(invite, office)
          IO.inspect send_email(email, office)
        email -> IO.inspect "Email existed"
      end
    end
    redirect(conn, to: Routes.invite_path(conn, :new, hash_id))

  end

  def accept(conn, %{"hash_id" => hash_id})  do
    user = Guardian.Plug.current_resource(conn)
    office_id = SunstoneWeb.UserController.decode_id(hash_id)
    office = Chats.get_office!(office_id)
    case Chats.get_invite_from_email!(user.email, office) do
      nil ->
        redirect(conn, to: Routes.office_path(conn, :index))
      invite -> 
        Chats.add_user_to_office(office, user, invite)
        redirect(conn, to: Routes.office_path(conn, :index))
    end
  end


   def send_email(email, office) do
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
                "email" => "noreply@inoffice.chat",
              },
              "subject" => "#{office.owner.name} send you an invitation",
              "content" => [
                %{"type"=> "text/html", "value" => "<h4 style=\"margin:0\">Your colleague #{office.owner.name} have invited you to join #{office.name} at Inoffice.</h4><a href=\"https://www.inoffice.chat/register\">Click Here to register</a>"}
              ]
              
          }
          url = "https://api.sendgrid.com/v3/mail/send"
        HTTPoison.post url, Poison.encode!(body), headers
  end



end
