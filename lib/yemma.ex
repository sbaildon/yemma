defmodule Yemma do
  @moduledoc """
  Yemma keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  use GenServer

  alias Yemma.{Config, Users}
  alias YemmaWeb.UserAuth

  def start_link(opts) do
    conf = Config.new(opts)
    GenServer.start_link(__MODULE__, conf, name: __MODULE__)
  end

  @impl true
  def init(conf) do
    {:ok, conf}
  end

  @impl true
  def handle_call(:config, _from, conf) do
    {:reply, conf, conf}
  end

  @type name :: term

  @spec config(name()) :: Config.t()
  def config(name \\ __MODULE__) do
    GenServer.call(name, :config)
  end

  def log_in_user(name \\ __MODULE__, conn, user) do
    name |> config() |> UserAuth.log_in_user(conn, user)
  end

  def log_out_user(name \\ __MODULE__, conn) do
    name |> config() |> UserAuth.log_out_user(conn)
  end

  def fetch_current_user(name \\ __MODULE__, conn, opts) do
    name |> config() |> UserAuth.fetch_current_user(conn, opts)
  end

  def require_authenticated_user(name \\ __MODULE__, conn, opts) do
    name |> config() |> UserAuth.require_authenticated_user(conn, opts)
  end

  @doc """
  Used for routes that require the user to not be authenticated.

  ## Options

    * `:to` - the destination to redirect the user to if they're already
      authenticated. Accepts either an mfa tuple or string. Falls back to "/"

  ## Examples

      plug :redirect_if_user_is_authenticated

      plug :redirect_if_user_is_authenticated, to: "https://example.com"

  Create a pipeline to redirect users to your dashboard if they're already authenticated

      pipeline :requires_unauthenticated_user do
        plug :redirect_if_user_is_authenticated, to: {MyAppWeb.Router.Helpers, :dashboard_url, [MyAppWeb.Endpoint, :index]}
      end

      scope "/", MyAppWeb do
        pipe_through [:browser, :requires_unauthenticated_user]

        get("/", PageController, :index)
      end

      scope "/dashboard", MyAppWeb do
        pipe_through [:browser]

        get("/", DashboardController, :index)
      end

  """
  def redirect_if_user_is_authenticated(name \\ __MODULE__, conn, opts) do
    name |> config() |> UserAuth.redirect_if_user_is_authenticated(conn, opts)
  end

  def get_user_by_email(name \\ __MODULE__, email) when is_binary(email) do
    name |> config() |> Users.get_user_by_email(email)
  end

  def get_user!(name \\ __MODULE__, id) do
    name |> config() |> Users.get_user!(id)
  end

  def register_user(name \\ __MODULE__, attrs) do
    name |> config() |> Users.register_user(attrs)
  end

  def register_or_get_by_email(name \\ __MODULE__, email) when is_binary(email) do
    name |> config() |> Users.register_or_get_by_email(email)
  end

  defdelegate change_user_registration(user, attrs \\ %{}), to: Users
  defdelegate change_user_email(user, attrs \\ %{}), to: Users
  defdelegate apply_user_email(user, attrs), to: Users

  def update_user_email(name \\ __MODULE__, user, token) do
    name |> config() |> Users.update_user_email(user, token)
  end

  def deliver_update_email_instructions(
        name \\ __MODULE__,
        user,
        current_email,
        update_email_url_fun
      ) do
    name
    |> config()
    |> Users.deliver_update_email_instructions(user, current_email, update_email_url_fun)
  end

  def generate_user_session_token(name \\ __MODULE__, user) do
    name |> config() |> Users.generate_user_session_token(user)
  end

  def get_user_by_session_token(name \\ __MODULE__, token) do
    name |> config() |> Users.get_user_by_session_token(token)
  end

  def delete_session_token(name \\ __MODULE__, token) do
    name |> config() |> Users.delete_session_token(token)
  end

  def deliver_magic_link_instructions(
        name \\ __MODULE__,
        user,
        magic_link_email_url_fun
      ) do
    name
    |> config()
    |> Users.deliver_magic_link_instructions(user, magic_link_email_url_fun)
  end

  def confirm_user(name \\ __MODULE__, token) do
    name |> config() |> Users.confirm_user(token)
  end

  def put_conn_config(conn, opts) do
    conf =
      Keyword.get(opts, :name, __MODULE__)
      |> config()

    UserAuth.put_private(conf, conn)
  end

  def sign_out_url(name \\ __MODULE__) do
    conf = name |> config()

    conf.routes.user_session_url(conf.endpoint, :delete)
  end
end
