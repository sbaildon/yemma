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
      assert redirected_to(conn) == "/"
      assert Users.get_user!(user.id).confirmed_at
      assert get_session(conn, :user_token)
      assert [%{context: "session", user_id: ^user_id} | []] = Repo.all(Users.UserToken)

      conn = get(conn, Routes.user_confirmation_path(conn, :edit, token))
      assert get_flash(conn, :error) =~ "Magic link is invalid or it has expired"
      assert redirected_to(conn) == Routes.user_session_path(conn, :new)
      assert [%{context: "session", user_id: ^user_id} | []] = Repo.all(Users.UserToken)
    end
  end

  describe "POST /users/confirm/:token" do
    test "confirms the given token once", %{conn: conn, user: user} do
      token =
        extract_user_token(fn url ->
          Users.deliver_magic_link_instructions(user, url)
        end)

      conn = post(conn, Routes.user_confirmation_path(conn, :update, token))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "User confirmed successfully"
      assert Users.get_user!(user.id).confirmed_at
      refute get_session(conn, :user_token)
      assert Repo.all(Users.UserToken) == []

      # When not logged in
      conn = post(conn, Routes.user_confirmation_path(conn, :update, token))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "User confirmation link is invalid or it has expired"

      # When logged in
      conn =
        build_conn()
        |> log_in_user(user)
        |> post(Routes.user_confirmation_path(conn, :update, token))

      assert redirected_to(conn) == "/"
      refute get_flash(conn, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, user: user} do
      conn = post(conn, Routes.user_confirmation_path(conn, :update, "oops"))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "User confirmation link is invalid or it has expired"
      refute Users.get_user!(user.id).confirmed_at
    end
  end
end
