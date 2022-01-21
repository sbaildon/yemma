defmodule YemmaWeb.UserAuthTest do
  use YemmaWeb.ConnCase

  import Yemma.UsersFixtures

  @remember_me_cookie "_yemma_web_user_remember_me"

  setup %{conn: conn} do
    conn =
      conn
      |> init_test_session(%{})

    %{user: user_fixture(yemma_config()), conn: conn}
  end

  describe "log_in_user/3" do
    test "stores the user token in the session", %{conn: conn, user: user} do
      start_supervised_yemma!()

      conn = Yemma.log_in_user(conn, user)
      assert token = get_session(conn, :user_token)
      assert get_session(conn, :live_socket_id) == "users_sessions:#{Base.url_encode64(token)}"
      assert redirected_to(conn) == "/"
      assert Yemma.get_user_by_session_token(token)
    end

    test "clears everything previously stored in the session", %{conn: conn, user: user} do
      start_supervised_yemma!()

      conn = conn |> put_session(:to_be_removed, "value") |> Yemma.log_in_user(user)
      refute get_session(conn, :to_be_removed)
    end

    test "redirects to the origin url", %{conn: conn, user: user} do
      start_supervised_yemma!()

      conn = conn |> put_session(:user_return_to, "/hello") |> Yemma.log_in_user(user)
      assert redirected_to(conn) == "/hello"
    end

    test "redirects to an mfa tuple", %{conn: conn, user: user} do
      {m, f, a} =
        {Phoenix.YemmaTest.Router.Helpers, :page_url, [Phoenix.YemmaTest.Endpoint, :index]}

      start_supervised_yemma!(signed_in_dest: {m, f, a})

      conn = Yemma.log_in_user(conn, user)
      assert redirected_to(conn) == apply(m, f, a)
    end

    test "redirects to a string", %{conn: conn, user: user} do
      redirect_to = "https://example.com"

      start_supervised_yemma!(signed_in_dest: redirect_to)

      conn = Yemma.log_in_user(conn, user)
      assert redirected_to(conn) == redirect_to
    end

    test "writes a cookie", %{conn: conn, user: user} do
      start_supervised_yemma!()

      conn = conn |> fetch_cookies() |> Yemma.log_in_user(user)
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

      start_supervised_yemma!(cookie_domain: cookie_domain)

      conn = conn |> fetch_cookies() |> Yemma.log_in_user(user)

      assert get_session(conn, :user_token) == conn.cookies[@remember_me_cookie]

      assert %{value: signed_token, max_age: max_age, domain: domain} =
               conn.resp_cookies[@remember_me_cookie]

      assert signed_token != get_session(conn, :user_token)
      assert max_age == 5_184_000
      assert domain == cookie_domain
    end
  end

  describe "logout_user/1" do
    test "erases session and cookies", %{conn: conn, user: user} do
      start_supervised_yemma!()

      user_token = Yemma.generate_user_session_token(user)

      conn =
        conn
        |> put_session(:user_token, user_token)
        |> put_req_cookie(@remember_me_cookie, user_token)
        |> fetch_cookies()
        |> Yemma.log_out_user()

      refute get_session(conn, :user_token)
      refute conn.cookies[@remember_me_cookie]
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == "/"
      refute Yemma.get_user_by_session_token(user_token)
    end

    test "does not broadcast if pubsub_server is not configured", %{conn: conn} do
      start_supervised_yemma!()

      live_socket_id = "users_sessions:abcdef-token"
      Phoenix.YemmaTest.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> Yemma.log_out_user()

      refute_received %Phoenix.Socket.Broadcast{event: "disconnect", topic: ^live_socket_id}
    end

    test "broadcasts to the given live_socket_id", %{conn: conn} do
      start_supervised_yemma!(pubsub_server: Phoenix.YemmaTest.PubSub)

      live_socket_id = "users_sessions:abcdef-token"
      Phoenix.YemmaTest.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> Yemma.log_out_user()

      assert_receive %Phoenix.Socket.Broadcast{event: "disconnect", topic: ^live_socket_id}
    end

    test "works even if user is already logged out", %{conn: conn} do
      start_supervised_yemma!()
      conn = conn |> fetch_cookies() |> Yemma.log_out_user()
      refute get_session(conn, :user_token)
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == "/"
    end
  end

  describe "fetch_current_user/2" do
    test "authenticates user from session", %{conn: conn, user: user} do
      start_supervised_yemma!()

      user_token = Yemma.generate_user_session_token(user)
      conn = conn |> put_session(:user_token, user_token) |> Yemma.fetch_current_user([])
      assert conn.assigns.current_user.id == user.id
    end

    test "authenticates user from cookies", %{conn: conn, user: user} do
      start_supervised_yemma!()

      logged_in_conn = conn |> fetch_cookies() |> Yemma.log_in_user(user)

      user_token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      conn =
        conn
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> Yemma.fetch_current_user([])

      assert get_session(conn, :user_token) == user_token
      assert conn.assigns.current_user.id == user.id
    end

    test "authenticates when conn originates from another app", %{conn: conn, user: user} do
      start_supervised_yemma!()
      logged_in_conn = conn |> fetch_cookies() |> Yemma.log_in_user(user)

      user_token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      conn =
        %{conn | secret_key_base: "another_apps_key"}
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> Yemma.fetch_current_user([])

      assert get_session(conn, :user_token) == user_token
      assert conn.assigns.current_user.id == user.id
    end

    test "does not authenticate if data is missing", %{conn: conn, user: user} do
      start_supervised_yemma!()

      _ = Yemma.generate_user_session_token(user)
      conn = Yemma.fetch_current_user(conn, [])
      refute get_session(conn, :user_token)
      refute conn.assigns.current_user
    end
  end

  describe "redirect_if_user_is_authenticated/2" do
    test "redirects if user is authenticated", %{conn: conn, user: user} do
      start_supervised_yemma!()

      conn = conn |> assign(:current_user, user) |> Yemma.redirect_if_user_is_authenticated([])
      assert conn.halted
      assert redirected_to(conn) == "/"
    end

    test "redirects to configured path", %{conn: conn, user: user} do
      start_supervised_yemma!()

      {m, f, a} =
        mfa = {Phoenix.YemmaTest.Router.Helpers, :page_url, [Phoenix.YemmaTest.Endpoint, :index]}

      opts = [to: mfa]

      conn = conn |> assign(:current_user, user) |> Yemma.redirect_if_user_is_authenticated(opts)

      assert conn.halted
      assert redirected_to(conn) == apply(m, f, a)
    end

    test "redirects to the provided mfa result", %{conn: conn, user: user} do
      start_supervised_yemma!()

      conn =
        conn
        |> assign(:current_user, user)
        |> Yemma.redirect_if_user_is_authenticated(
          to: {String, :replace, ["http://_.com", "_", "example"]}
        )

      assert conn.halted
      assert redirected_to(conn) == "http://example.com"
    end

    test "does not redirect if user is not authenticated", %{conn: conn} do
      start_supervised_yemma!()

      conn = Yemma.redirect_if_user_is_authenticated(conn, [])
      refute conn.halted
      refute conn.status
    end
  end

  describe "require_authenticated_user/2" do
    setup %{conn: conn} = context do
      %{context | conn: put_endpoint(conn)}
    end

    test "redirects if user is not authenticated", %{conn: conn} do
      conf = start_supervised_yemma!()

      conn = conn |> Yemma.require_authenticated_user([])
      assert conn.halted
      assert queryless_redirected_to(conn) == conf.routes.user_session_url(conn, :new)
    end

    test "forwards the return to destination as a query param", %{conn: conn} do
      start_supervised_yemma!()

      halted_conn =
        %{conn | path_info: ["foo"], query_string: ""}
        |> Yemma.require_authenticated_user([])

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
      start_supervised_yemma!()

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar", method: "POST"}
        |> Yemma.require_authenticated_user([])

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
      start_supervised_yemma!()
      conn = conn |> assign(:current_user, user) |> Yemma.require_authenticated_user([])
      refute conn.halted
      refute conn.status
    end
  end
end
