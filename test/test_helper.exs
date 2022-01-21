Application.put_env(:yemma, Phoenix.YemmaTest.Endpoint,
  url: [host: "localhost", port: 4001],
  secret_key_base: "LQLOmWs21foxaxwrEH+7lmarzFHYaAULHBl5pzdoFeZtEo/+wN0SAH0XAdkxz9i0",
  live_view: [signing_salt: "FaCYJ5ez"],
  render_errors: [view: Phoenix.YemmaTest.ErrorView],
  check_origin: false,
  pubsub_server: Phoenix.YemmaTest.PubSub
)

YemmaTest.Repo.start_link()
Ecto.Adapters.SQL.Sandbox.mode(YemmaTest.Repo, :manual)

defmodule Phoenix.YemmaTest.ErrorView do
  use Phoenix.View, root: "test/templates"

  def template_not_found(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end

defmodule Phoenix.YemmaTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :yemma

  plug Plug.Session,
    store: :cookie,
    key: "_live_view_key",
    signing_salt: "+6VTmn3nCp3U"

  plug Phoenix.YemmaTest.Router
end

defmodule Phoenix.YemmaTest.PageController do
  use YemmaWeb, :controller

  def index(conn, _params) do
    text(conn, "blank page")
  end
end

defmodule Phoenix.YemmaTest.Router do
  use Phoenix.Router

  import Yemma,
    only: [
      redirect_if_user_is_authenticated: 2,
      require_authenticated_user: 2,
      fetch_current_user: 2,
      put_name_in_conn: 2
    ]

  pipeline :browser do
    plug :fetch_session
    plug :fetch_flash
    plug :fetch_query_params
    plug :put_name_in_conn
    plug :fetch_current_user
  end

  scope "/", Phoenix.YemmaTest do
    pipe_through [:browser]

    get "/", PageController, :index
  end

  scope "/", YemmaWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/sign_in", UserSessionController, :new
    post "/sign_in", UserSessionController, :create
  end

  scope "/", YemmaWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/settings", UserSettingsController, :edit
    put "/settings", UserSettingsController, :update
    get "/settings/confirm_email/:token", UserSettingsController, :confirm_email
  end

  scope "/", YemmaWeb do
    pipe_through [:browser]

    delete "/log_out", UserSessionController, :delete
    get "/confirm/:token", UserConfirmationController, :edit
  end
end

Application.put_env(:yemma_test, Yemma,
  routes: Phoenix.YemmaTest.Router.Helpers,
  signed_in_dest:
    {Phoenix.YemmaTest.Router.Helpers, :page_url, [Phoenix.YemmaTest.Endpoint, :index]}
)

Supervisor.start_link(
  [
    {Phoenix.PubSub, name: Phoenix.YemmaTest.PubSub, adapter: Phoenix.PubSub.PG2},
    Phoenix.YemmaTest.Endpoint
  ],
  strategy: :one_for_one
)

ExUnit.start()
