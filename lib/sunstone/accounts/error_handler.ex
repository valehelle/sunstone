defmodule Sunstone.Accounts.ErrorHandler do
  import Plug.Conn

  def auth_error(conn, {type, _reason}, _opts) do
    case type do
      :unauthenticated -> 
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(200, "error")
    end
  end
end