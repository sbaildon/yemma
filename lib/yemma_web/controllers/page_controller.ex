defmodule YemmaWeb.PageController do
  use YemmaWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
