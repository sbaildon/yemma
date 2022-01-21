defmodule YemmaWeb.UserConfirmationController do
  use YemmaWeb, :controller

  def edit(conn, %{"token" => token}, yemma) do
    case Yemma.confirm_user(yemma.name, token) do
      {:ok, user} ->
        Yemma.log_in_user(yemma.name, conn, user)

      :error ->
        conn
        |> put_flash(:error, "Magic link is invalid or it has expired")
        |> redirect(to: yemma.routes.user_session_path(conn, :new))
    end
  end
end
