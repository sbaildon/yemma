defmodule YemmaWeb.UserConfirmationController do
  use YemmaWeb, :controller

  alias Yemma.Users
  alias YemmaWeb.UserAuth

  def edit(conn, %{"token" => token}) do
    case Users.confirm_user(token) do
      {:ok, user} ->
        conn
        |> UserAuth.log_in_user(user)

      :error ->
        conn
        |> put_flash(:error, "Magic link is invalid or it has expired")
        |> redirect(to: Routes.user_session_path(conn, :new))
    end
  end
end
