defmodule YemmaWeb.UserConfirmationControllerTest do
  use YemmaWeb.ConnCase

  alias Yemma.Users
  alias Yemma.Repo
  import Yemma.UsersFixtures

  setup do
    %{user: user_fixture()}
  end

  describe "GET /users/confirm/:token" do
    test "does not create a session from an invalid token", %{conn: conn} do
      conn = get(conn, Routes.user_confirmation_path(conn, :edit, "garbage"))
      assert redirected_to(conn) == Routes.user_session_path(conn, :new)
      refute get_session(conn, :user_token)
      assert [] = Repo.all(Users.UserToken)
    end

    test "confirms the given token once", %{conn: conn, user: %{id: user_id} = user} do
      token =
        extract_user_token(fn url ->
          Users.deliver_magic_link_instructions(user, url)
        end)

      conn = get(conn, Routes.user_confirmation_path(conn, :edit, token))
      assert redirected_to(conn) == Routes.user_settings_url(@endpoint, :edit)
      assert Users.get_user!(user.id).confirmed_at
      assert get_session(conn, :user_token)
      assert [%{context: "session", user_id: ^user_id} | []] = Repo.all(Users.UserToken)

      conn = get(conn, Routes.user_confirmation_path(conn, :edit, token))
      assert get_flash(conn, :error) =~ "Magic link is invalid or it has expired"
      assert redirected_to(conn) == Routes.user_session_path(conn, :new)
      assert [%{context: "session", user_id: ^user_id} | []] = Repo.all(Users.UserToken)
    end
  end
end
