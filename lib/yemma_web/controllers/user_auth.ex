defmodule YemmaWeb.UserAuth do
  import Plug.Conn
  import Phoenix.Controller

  alias Yemma.Users

  # Make the remember me cookie valid for 60 days.
  # If you want bump or reduce this value, also change
  # the token expiry itself in UserToken.
  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_yemma_web_user_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  @doc """
  Logs the user in.

  It renews the session ID and clears the whole session
  to avoid fixation attacks. See the renew_session
  function to customize this behaviour.

  It also sets a `:live_socket_id` key in the session,
  so LiveView sessions are identified and automatically
  disconnected on log out. The line can be safely removed
  if you are not using LiveView.
  """
  def log_in_user(conn, user) do
    token = Users.generate_user_session_token(user)
    user_return_to = get_session(conn, :user_return_to)

    conn
    |> renew_session()
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
    |> with_issuing_secret_key(fn conn ->
      put_resp_cookie(
        conn,
        @remember_me_cookie,
        token,
        @remember_me_options ++ [domain: cookie_domain(conn)]
      )
    end)
    |> redirect(external: user_return_to || signed_in_path())
  end

  defp cookie_domain(conn), do: Application.get_env(:yemma, :cookie_domain) || conn.host()

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session(conn) do
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  @doc """
  Logs the user out.

  It clears all session data for safety. See renew_session.
  """
  def log_out_user(conn) do
    user_token = get_session(conn, :user_token)
    user_token && Users.delete_session_token(user_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      pubsub = Application.get_env(:yemma, :pubsub_server)

      pubsub &&
        Phoenix.PubSub.broadcast(pubsub, live_socket_id, %Phoenix.Socket.Broadcast{
          event: "disconnect",
          topic: live_socket_id
        })
    end

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: "/")
  end

  @doc """
  Authenticates the user by looking into the session
  and remember me token.
  """
  def fetch_current_user(conn, _opts) do
    {user_token, conn} = ensure_user_token(conn)
    user = user_token && Users.get_user_by_session_token(user_token)
    assign(conn, :current_user, user)
  end

  defp ensure_user_token(conn) do
    if user_token = get_session(conn, :user_token) do
      {user_token, conn}
    else
      conn =
        conn
        |> with_issuing_secret_key(fn conn ->
          fetch_cookies(conn, signed: [@remember_me_cookie])
        end)

      if user_token = conn.cookies[@remember_me_cookie] do
        {user_token, put_session(conn, :user_token, user_token)}
      else
        {nil, conn}
      end
    end
  end

  defp with_issuing_secret_key(conn, function) when is_function(function, 1) do
    issuing_secret_key = Application.fetch_env!(:yemma, :secret_key_base)
    original_secret_key = Map.fetch!(conn, :secret_key_base)

    conn
    |> Map.replace!(:secret_key_base, issuing_secret_key)
    |> function.()
    |> Map.replace!(:secret_key_base, original_secret_key)
  end

  @doc """
  Used for routes that require the user to not be authenticated.
  """
  def redirect_if_user_is_authenticated(conn, opts) do
    if conn.assigns[:current_user] do
      redirect_to = parse_redirect_to(opts)

      conn
      |> redirect(external: redirect_to)
      |> halt()
    else
      conn
    end
  end

  defp parse_redirect_to(opts) do
    case opts[:to] do
      nil ->
        signed_in_path()

      {m, f, a} ->
        apply(m, f, a)
    end
  end

  @doc """
  Used for routes that require the user to be authenticated.

  If you want to enforce the user email is confirmed before
  they use the application at all, here would be a good place.
  """
  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      query = maybe_forward_return_to(conn)

      conn
      |> redirect(external: "/sign_in#{query}")
      |> halt()
    end
  end

  defp maybe_forward_return_to(%{method: "GET"} = conn) do
    %{return_to: request_url(conn)}
    |> URI.encode_query()
    |> then(&"?#{&1}")
  end

  defp maybe_forward_return_to(_), do: []

  defp signed_in_path() do
    case Application.get_env(:yemma, :signed_in_path) do
      {m, f, a} ->
        apply(m, f, a)

      nil ->
        "/"
    end
  end
end
