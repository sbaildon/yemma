defmodule YemmaWeb.UserConfirmationControllerTest do
  use YemmaWeb.ConnCase

  alias Yemma.Users
  import Yemma.UsersFixtures
  alias YemmaTest.Repo

  setup do
    conf = start_supervised_yemma!()
    %{user: user_fixture(conf), conf: conf}
  end

  describe "GET /users/confirm/:token" do
    test "does not create a session from an invalid token", %{conn: conn, conf: conf} do
      conn = get(conn, conf.routes.user_confirmation_path(conn, :edit, "garbage"))
      assert redirected_to(conn)
      refute get_session(conn, :user_token)
      assert [] = Repo.all(Users.UserToken)
    end

    test "confirms the given token once", %{conn: conn, user: %{id: user_id} = user, conf: conf} do
      token =
        extract_user_token(fn url ->
          Yemma.deliver_magic_link_instructions(conf.name, user, url)
        end)

      conn = get(conn, conf.routes.user_confirmation_path(conn, :edit, token))
      assert redirected_to(conn)
      assert Yemma.get_user!(conf.name, user.id).confirmed_at
      assert get_session(conn, :user_token)
      assert [%{context: "session", user_id: ^user_id} | []] = Repo.all(Users.UserToken)

      conn = get(conn, conf.routes.user_confirmation_path(conn, :edit, token))
      assert get_flash(conn, :error) =~ "Magic link is invalid or it has expired"
      assert redirected_to(conn) == conf.routes.user_session_path(conn, :new)
      assert [%{context: "session", user_id: ^user_id} | []] = Repo.all(Users.UserToken)
    end
  end
end
