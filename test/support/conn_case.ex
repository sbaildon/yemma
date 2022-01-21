defmodule YemmaWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use YemmaWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import YemmaWeb.ConnCase
      import Yemma.Case

      defdelegate view_template(conn), to: Phoenix.Controller

      # The default endpoint for testing
      @endpoint Phoenix.YemmaTest.Endpoint

      def put_endpoint(conn), do: put_private(conn, :phoenix_endpoint, @endpoint)
    end
  end

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(YemmaTest.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that registers and logs in users.

      setup :register_and_log_in_user

  It stores an updated connection and a registered user in the
  test context.
  """
  def register_and_log_in_user(%{conn: conn}) do
    name = Yemma.Case.start_supervised_yemma!()
    conf = Yemma.config(name)

    user = Yemma.UsersFixtures.user_fixture(conf)
    %{conn: log_in_user(conn, conf.name, user), user: user, conf: conf}
  end

  @doc """
  Logs the given `user` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_user(conn, name, user) do
    token = Yemma.generate_user_session_token(name, user)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
  end

  @doc """
  Removes the query from the redirect location
  so that it may be compared directly to route helpers
  """
  def queryless_redirected_to(conn) do
    conn
    |> Phoenix.ConnTest.redirected_to()
    |> URI.parse()
    |> Map.replace!(:query, nil)
    |> URI.to_string()
  end
end
