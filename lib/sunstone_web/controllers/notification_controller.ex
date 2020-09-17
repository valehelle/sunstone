defmodule SunstoneWeb.NotificationController do
  use SunstoneWeb, :controller
  alias Sunstone.Accounts
  def new(conn, param) do
    user = Guardian.Plug.current_resource(conn)
    Accounts.create_update_notifications(param,user)
    send_resp(conn, :ok, "")
  end


end
