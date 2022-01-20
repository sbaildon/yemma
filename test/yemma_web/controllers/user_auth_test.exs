defmodule YemmaWeb.UserAuthTest do
  use YemmaWeb.ConnCase

  alias Yemma.Users
  alias YemmaWeb.UserAuth
  import Yemma.UsersFixtures

  @remember_me_cookie "_yemma_web_user_remember_me"

  setup %{conn: conn} do
    conn =
      conn
      |> init_test_session(%{})

    %{user: user_fixture(), conn: conn}
  end

  describe "log_in_user/3" do
    test "stores the user token in the session", %{conn: conn, user: user} do
      conn = UserAuth.log_in_user(conn, user)
      assert token = get_session(conn, :user_token)
      assert get_session(conn, :live_socket_id) == "users_sessions:#{Base.url_encode64(token)}"
      assert redirected_to(conn) == "/"
      assert Users.get_user_by_session_token(token)
    end

    test "clears everything previously stored in the session", %{conn: conn, user: user} do
      conn = conn |> put_session(:to_be_removed, "value") |> UserAuth.log_in_user(user)
      refute get_session(conn, :to_be_removed)
    end

    test "redirects to the origin url", %{conn: conn, user: user} do
      conn = conn |> put_session(:user_return_to, "/hello") |> UserAuth.log_in_user(user)
      assert redirected_to(conn) == "/hello"
    end

    test "redirects to the configured url", %{conn: conn, user: user} do
      {m, f, a} =
        {Phoenix.YemmaTest.Router.Helpers, :page_url, [Phoenix.YemmaTest.Endpoint, :index]}

      Application.put_env(
        :yemma,
        :signed_in_path,
        {m, f, a}
      )

      conn = UserAuth.log_in_user(conn, user)
      assert redirected_to(conn) == apply(m, f, a)

      Application.delete_env(:yemma, :signed_in_path)
    end

    test "writes a cookie", %{conn: conn, user: user} do
      conn = conn |> fetch_cookies() |> UserAuth.log_in_user(user)
      assert get_session(conn, :user_token) == conn.cookies[@remember_me_cookie]

      assert %{value: signed_token, max_age: max_age, domain: domain} =
               conn.resp_cookies[@remember_me_cookie]

      assert signed_token != get_session(conn, :user_token)
      assert max_age == 5_184_000
      assert domain == conn.host
    end

    test "writes a cookie to a custom domain", %{conn: conn, user: user} do
      auth_host = Regex.replace(~r/www/, conn.host, "auth")
      cookie_domain = Regex.replace(~r/auth/, auth_host, "")
      Application.put_env(:yemma, :cookie_domain, cookie_domain)

      conn =
        conn |> fetch_cookies() |> UserAuth.log_in_user(user) |> Map.replace!(:host, auth_host)

      assert get_session(conn, :user_token) == conn.cookies[@remember_me_cookie]

      assert %{value: signed_token, max_age: max_age, domain: domain} =
               conn.resp_cookies[@remember_me_cookie]

      assert signed_token != get_session(conn, :user_token)
      assert max_age == 5_184_000
      assert domain == cookie_domain

      Application.delete_env(:yemma, :cookie_domain)
    end

    test "again", %{conn: conn, user: user} do
      Application.put_env(:yemma, :cookie_domain, ".example.com")
      conn = conn |> fetch_cookies() |> UserAuth.log_in_user(user)
      assert get_session(conn, :user_token) == conn.cookies[@remember_me_cookie]

      assert %{value: signed_token, max_age: max_age, domain: domain} =
               conn.resp_cookies[@remember_me_cookie]

      assert signed_token != get_session(conn, :user_token)
      assert max_age == 5_184_000
      assert domain == ".example.com"
      Application.delete_env(:yemma, :cookie_domain)
    end
  end

  describe "logout_user/1" do
    test "erases session and cookies", %{conn: conn, user: user} do
      user_token = Users.generate_user_session_token(user)

      conn =
        conn
        |> put_session(:user_token, user_token)
        |> put_req_cookie(@remember_me_cookie, user_token)
        |> fetch_cookies()
        |> UserAuth.log_out_user()

      refute get_session(conn, :user_token)
      refute conn.cookies[@remember_me_cookie]
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == "/"
      refute Users.get_user_by_session_token(user_token)
    end

    test "broadcasts to the given live_socket_id", %{conn: conn} do
      live_socket_id = "users_sessions:abcdef-token"
      Phoenix.YemmaTest.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> UserAuth.log_out_user()

      assert_receive %Phoenix.Socket.Broadcast{event: "disconnect", topic: ^live_socket_id}
    end

    test "works even if user is already logged out", %{conn: conn} do
      conn = conn |> fetch_cookies() |> UserAuth.log_out_user()
      refute get_session(conn, :user_token)
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == "/"
    end
  end

  describe "fetch_current_user/2" do
    test "authenticates user from session", %{conn: conn, user: user} do
      user_token = Users.generate_user_session_token(user)
      conn = conn |> put_session(:user_token, user_token) |> UserAuth.fetch_current_user([])
      assert conn.assigns.current_user.id == user.id
    end

    test "authenticates user from cookies", %{conn: conn, user: user} do
      logged_in_conn = conn |> fetch_cookies() |> UserAuth.log_in_user(user)

      user_token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      conn =
        conn
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> UserAuth.fetch_current_user([])

      assert get_session(conn, :user_token) == user_token
      assert conn.assigns.current_user.id == user.id
    end

    test "authenticates when conn originates from another app", %{
      conn: conn,
      user: user
    } do
      logged_in_conn = conn |> fetch_cookies() |> UserAuth.log_in_user(user)

      user_token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      conn =
        %{conn | secret_key_base: "another_apps_key"}
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> UserAuth.fetch_current_user([])

      assert get_session(conn, :user_token) == user_token
      assert conn.assigns.current_user.id == user.id
    end

    test "does not authenticate if data is missing", %{conn: conn, user: user} do
      _ = Users.generate_user_session_token(user)
      conn = UserAuth.fetch_current_user(conn, [])
      refute get_session(conn, :user_token)
      refute conn.assigns.current_user
    end
  end

  describe "redirect_if_user_is_authenticated/2" do
    test "redirects if user is authenticated", %{conn: conn, user: user} do
      conn = conn |> assign(:current_user, user) |> UserAuth.redirect_if_user_is_authenticated([])
      assert conn.halted
      assert redirected_to(conn) == "/"
    end

    test "redirects to configured path", %{conn: conn, user: user} do
      {m, f, a} =
        {Phoenix.YemmaTest.Router.Helpers, :page_url, [Phoenix.YemmaTest.Endpoint, :index]}

      Application.put_env(
        :yemma,
        :signed_in_path,
        {m, f, a}
      )

      conn = conn |> assign(:current_user, user) |> UserAuth.redirect_if_user_is_authenticated([])
      assert conn.halted
      assert redirected_to(conn) == apply(m, f, a)

      Application.delete_env(:yemma, :signed_in_path)
    end

    test "redirects to the provided mfa result", %{conn: conn, user: user} do
      conn =
        conn
        |> assign(:current_user, user)
        |> UserAuth.redirect_if_user_is_authenticated(
          to: {String, :replace, ["http://_.com", "_", "example"]}
        )

      assert conn.halted
      assert redirected_to(conn) == "http://example.com"
    end

    test "does not redirect if user is not authenticated", %{conn: conn} do
      conn = UserAuth.redirect_if_user_is_authenticated(conn, [])
      refute conn.halted
      refute conn.status
    end
  end

  describe "require_authenticated_user/2" do
    setup %{conn: conn} = context do
      %{context | conn: put_endpoint(conn)}
    end

    test "redirects if user is not authenticated", %{conn: conn} do
      conn = conn |> UserAuth.require_authenticated_user([])
      assert conn.halted
      assert queryless_redirected_to(conn) == Routes.user_session_url(conn, :new)
    end

    test "forwards the return to destination as a query param", %{conn: conn} do
      halted_conn =
        %{conn | path_info: ["foo"], query_string: ""}
        |> UserAuth.require_authenticated_user([])

      return_to_query_param =
        halted_conn
        |> Plug.Conn.get_resp_header("location")
        |> List.first()
        |> URI.parse()
        |> Map.fetch!(:query)
        |> URI.decode_query()
        |> Map.fetch!("return_to")

      assert halted_conn.halted
      assert return_to_query_param == "http://www.example.com/"
    end

    test "does not forward return to destination if POST", %{conn: conn} do
      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar", method: "POST"}
        |> UserAuth.require_authenticated_user([])

      return_to_query_param =
        halted_conn
        |> Plug.Conn.get_resp_header("location")
        |> List.first()
        |> URI.parse()
        |> Map.fetch!(:query)

      assert halted_conn.halted
      refute return_to_query_param
    end

    test "does not redirect if user is authenticated", %{conn: conn, user: user} do
      conn = conn |> assign(:current_user, user) |> UserAuth.require_authenticated_user([])
      refute conn.halted
      refute conn.status
    end
  end
end
