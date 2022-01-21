defmodule YemmaWeb.UserSessionController do
  use YemmaWeb, :controller

  def new(conn, params, _name) do
    conn
    |> maybe_store_return_to(params)
    |> render("new.html", error_message: nil)
  end

  defp maybe_store_return_to(conn, %{"return_to" => return_to}),
    do: put_session(conn, :user_return_to, return_to)

  defp maybe_store_return_to(conn, _params), do: delete_session(conn, :user_return_to)

  def create(conn, %{"user" => user_params}, name) do
    %{"email" => email} = user_params

    with {:ok, user} <- Yemma.register_or_get_by_email(name, email) do
      Yemma.deliver_magic_link_instructions(
        name,
        user,
        &routes().user_confirmation_url(conn, :edit, &1)
      )

      conn
      |> put_flash(:info, "Magic link sent")
      |> render("magic.html", user: user)
    else
      {:error, _changeset} ->
        render(conn, "new.html", error_message: "something went wrong")
    end
  end

  def delete(conn, _params, name) do
    conn =
      conn
      |> put_flash(:info, "Logged out successfully.")

    Yemma.log_out_user(name, conn)
  end
end
