defmodule SunstoneWeb.TestController do
  use SunstoneWeb, :controller

  def index(conn, _) do
    user = %{name: "hazmi"}
    Sunstone.Store.update_user_location(user)
    IO.inspect Sunstone.Store.state
    render(conn, "index.html")
  end 

  def index_2(conn, _) do
    render(conn, "index2.html")
  end 
end
