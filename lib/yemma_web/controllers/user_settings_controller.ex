defmodule YemmaWeb.UserSettingsController do
  use YemmaWeb, :controller

  alias Yemma.Users

  plug :assign_email_changesets

  def edit(conn, _params, _name) do
    render(conn, "edit.html")
  end

  def update(conn, %{"action" => "update_email"} = params, name) do
    %{"user" => user_params} = params
    user = conn.assigns.current_user

    case Users.apply_user_email(user, user_params) do
      {:ok, applied_user} ->
        Yemma.deliver_update_email_instructions(
          name,
          applied_user,
          user.email,
          &routes().user_settings_url(conn, :confirm_email, &1)
        )

        conn
        |> put_flash(
          :info,
          "A link to confirm your email change has been sent to the new address."
        )
        |> redirect(to: routes().user_settings_path(conn, :edit))

      {:error, changeset} ->
        render(conn, "edit.html", email_changeset: changeset)
    end
  end

  def confirm_email(conn, %{"token" => token}, name) do
    case Yemma.update_user_email(name, conn.assigns.current_user, token) do
      :ok ->
        conn
        |> put_flash(:info, "Email changed successfully.")
        |> redirect(to: routes().user_settings_path(conn, :edit))

      :error ->
        conn
        |> put_flash(:error, "Email change link is invalid or it has expired.")
        |> redirect(to: routes().user_settings_path(conn, :edit))
    end
  end

  defp assign_email_changesets(conn, _opts) do
    user = conn.assigns.current_user

    conn
    |> assign(:email_changeset, Users.change_user_email(user))
  end
end
