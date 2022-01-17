defmodule YemmaWeb.UserSessionController do
  use YemmaWeb, :controller

  alias Yemma.Users
  alias YemmaWeb.UserAuth

  def new(conn, params) do
    conn
    |> maybe_store_return_to(params)
    |> render("new.html", error_message: nil)
  end

  defp maybe_store_return_to(conn, %{"return_to" => return_to}),
    do: put_session(conn, :user_return_to, return_to)

  defp maybe_store_return_to(conn, _params), do: delete_session(conn, :user_return_to)

  def create(conn, %{"user" => user_params}) do
    %{"email" => email} = user_params

    with {:ok, user} <- Users.register_or_get_by_email(email) do
      Users.deliver_magic_link_instructions(
        user,
        &Routes.user_confirmation_url(conn, :edit, &1)
      )

      conn
      |> put_flash(:info, "Magic link sent")
      |> render("magic.html", user: user)
    else
      {:error, _changeset} ->
        render(conn, "new.html", error_message: "something went wrong")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
