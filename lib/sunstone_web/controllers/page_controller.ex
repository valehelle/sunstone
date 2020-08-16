defmodule SunstoneWeb.PageController do
  use SunstoneWeb, :controller

  def landing(conn, _params) do
    render conn, "index.html"
  end
  def contact(conn, _params) do
    render conn, "contact.html"
  end


end
