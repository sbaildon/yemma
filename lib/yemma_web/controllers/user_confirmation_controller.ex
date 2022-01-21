defmodule YemmaWeb.UserConfirmationController do
  use YemmaWeb, :controller

  def edit(conn, %{"token" => token}, name) do
    case Yemma.confirm_user(name, token) do
      {:ok, user} ->
        conn
        |> Yemma.log_in_user(user)

      :error ->
        conn
        |> put_flash(:error, "Magic link is invalid or it has expired")
        |> redirect(to: routes().user_session_path(conn, :new))
    end
  end
end
