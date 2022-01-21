defmodule YemmaWeb.UserSettingsControllerTest do
  use YemmaWeb.ConnCase

  alias Yemma.Users
  import Yemma.UsersFixtures

  setup :register_and_log_in_user

  describe "GET /users/settings" do
    test "renders settings page", %{conn: conn, conf: conf} do
      conn = get(conn, conf.routes.user_settings_path(conn, :edit))
      response = html_response(conn, 200)
      assert response =~ "<h1>Settings</h1>"
    end

    test "redirects if user is not logged in", %{conf: conf} do
      conn = build_conn()
      conn = get(conn, conf.routes.user_settings_path(conn, :edit))
      assert queryless_redirected_to(conn) == conf.routes.user_session_url(conn, :new)
    end
  end

  describe "PUT /users/settings (change email form)" do
    @tag :capture_log
    test "updates the user email", %{conn: conn, user: user, conf: conf} do
      conn =
        put(conn, conf.routes.user_settings_path(conn, :update), %{
          "action" => "update_email",
          "user" => %{"email" => unique_user_email()}
        })

      assert redirected_to(conn) == conf.routes.user_settings_path(conn, :edit)
      assert Users.get_user_by_email(conf, user.email)
    end

    test "does not update email on invalid data", %{conn: conn, conf: conf} do
      conn =
        put(conn, conf.routes.user_settings_path(conn, :update), %{
          "action" => "update_email",
          "user" => %{"email" => "with spaces"}
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Settings</h1>"
      assert response =~ "must have the @ sign and no spaces"
    end
  end

  describe "GET /users/settings/confirm_email/:token" do
    setup %{user: user, conf: conf} do
      email = unique_user_email()

      token =
        extract_user_token(fn url ->
          Users.deliver_update_email_instructions(conf, %{user | email: email}, user.email, url)
        end)

      %{token: token, email: email}
    end

    test "updates the user email once", %{
      conn: conn,
      user: user,
      token: token,
      email: email,
      conf: conf
    } do
      conn = get(conn, conf.routes.user_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == conf.routes.user_settings_path(conn, :edit)
      assert get_flash(conn, :info) =~ "Email changed successfully"
      refute Users.get_user_by_email(conf, user.email)
      assert Users.get_user_by_email(conf, email)

      conn = get(conn, conf.routes.user_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == conf.routes.user_settings_path(conn, :edit)
      assert get_flash(conn, :error) =~ "Email change link is invalid or it has expired"
    end

    test "does not update email with invalid token", %{conn: conn, user: user, conf: conf} do
      conn = get(conn, conf.routes.user_settings_path(conn, :confirm_email, "oops"))
      assert redirected_to(conn) == conf.routes.user_settings_path(conn, :edit)
      assert get_flash(conn, :error) =~ "Email change link is invalid or it has expired"
      assert Users.get_user_by_email(conf, user.email)
    end

    test "redirects if user is not logged in", %{token: token, conf: conf} do
      conn = build_conn()
      conn = get(conn, conf.routes.user_settings_path(conn, :confirm_email, token))
      assert queryless_redirected_to(conn) == conf.routes.user_session_url(conn, :new)
    end
  end
end
