defmodule YemmaWeb.UserSessionControllerTest do
  use YemmaWeb.ConnCase

  import Yemma.UsersFixtures

  setup do
    name = start_supervised_yemma!()
    conf = Yemma.config(name)
    %{user: user_fixture(conf)}
  end

  describe "GET /users/log_in" do
    test "renders log in page", %{conn: conn} do
      conn = get(conn, Routes.user_session_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Log in</h1>"
    end

    test "redirects if already logged in", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> get(Routes.user_session_path(conn, :new))
      assert redirected_to(conn)
    end

    test "saves return to location if passed as a query param", %{conn: conn} do
      return_to = "http://example.com"
      conn = get(conn, Routes.user_session_path(conn, :new, return_to: return_to))
      assert get_session(conn, :user_return_to) == return_to

      conn = get(conn, Routes.user_session_path(conn, :new))
      refute get_session(conn, :user_return_to)
    end
  end

  describe "POST /users/log_in" do
    test "presents instructions for magic link", %{conn: conn, user: user} do
      conn =
        conn
        |> post(Routes.user_session_path(conn, :create), %{
          "user" => %{
            "email" => user.email
          }
        })

      assert view_template(conn) == "magic.html"
      assert conn.assigns.user.id == user.id
    end

    test "renders log in page if unable to find user for any reason", %{conn: conn} do
      conn =
        conn
        |> post(Routes.user_session_path(conn, :create), %{
          "user" => %{
            "email" => "invalid"
          }
        })

      assert view_template(conn) == "new.html"
    end
  end

  describe "DELETE /users/log_out" do
    test "logs the user out", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> delete(Routes.user_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
      refute get_session(conn, :user_token)
      assert get_flash(conn, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the user is not logged in", %{conn: conn} do
      conn = delete(conn, Routes.user_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
      refute get_session(conn, :user_token)
      assert get_flash(conn, :info) =~ "Logged out successfully"
    end
  end
end
