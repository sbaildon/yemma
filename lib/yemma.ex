defmodule Yemma do
  @moduledoc """
  Yemma keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  use GenServer

  alias Yemma.Config
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

  defdelegate fetch_current_user(conn, opts), to: UserAuth

  defdelegate require_authenticated_user(conn, opts), to: UserAuth

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
end
