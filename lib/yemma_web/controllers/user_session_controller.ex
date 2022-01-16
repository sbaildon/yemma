defmodule YemmaWeb.UserSessionController do
  use YemmaWeb, :controller

  alias Yemma.Users
  alias YemmaWeb.UserAuth

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"user" => user_params}) do
    %{"email" => email} = user_params

    with {:ok, user} <- Users.register_or_get_by_email(email) do
      Users.deliver_user_confirmation_instructions(
        user,
        &Routes.user_confirmation_url(conn, :edit, &1)
      )

      render(conn, "magic.html", user: user)
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
