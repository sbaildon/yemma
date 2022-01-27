defmodule Yemma.UsersTest do
  use Yemma.DataCase

  alias Yemma.Users

  import Yemma.UsersFixtures
  alias Yemma.Users.{UserToken}

  setup do
    %{conf: yemma_config()}
  end

  describe "get_user_by_email/1" do
    test "does not return the user if the email does not exist", %{conf: conf} do
      refute Users.get_user_by_email(conf, "unknown@example.com")
    end

    test "returns the user if the email exists", %{conf: conf} do
      %{id: id} = user = user_fixture(conf)
      assert %_{id: ^id} = Users.get_user_by_email(conf, user.email)
    end
  end

  describe "get_user!/1" do
    test "raises if id is invalid", %{conf: conf} do
      assert_raise Ecto.NoResultsError, fn ->
        case conf.user.__schema__(:type, :id) do
          :string ->
            Users.get_user!(conf, "does_not_exist")

          :integer ->
            Users.get_user!(conf, -1)
        end
      end
    end

    test "returns the user with the given id", %{conf: conf} do
      %{id: id} = user = user_fixture(conf)
      assert %_{id: ^id} = Users.get_user!(conf, user.id)
    end
  end

  describe "register_user/1" do
    test "requires email to be set", %{conf: conf} do
      {:error, changeset} = Users.register_user(conf, %{})

      assert %{
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email when given", %{conf: conf} do
      {:error, changeset} = Users.register_user(conf, %{email: "not valid"})

      assert %{
               email: ["must have the @ sign and no spaces"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email for security", %{conf: conf} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Users.register_user(conf, %{email: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{conf: conf} do
      %{email: email} = user_fixture(conf)
      {:error, changeset} = Users.register_user(conf, %{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Users.register_user(conf, %{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers users", %{conf: conf} do
      email = unique_user_email()
      {:ok, user} = Users.register_user(conf, valid_user_attributes(email: email))
      assert user.email == email
      assert is_nil(user.confirmed_at)
    end
  end

  describe "register_or_get_by_email/1" do
    test "gets an existing user", %{conf: conf} do
      %{email: email} = user_fixture(conf)

      {:ok, user} = Users.register_or_get_by_email(conf, email)
      assert user.email == email
    end

    test "registers if email doesn't exist", %{conf: conf} do
      email = unique_user_email()
      {:ok, user} = Users.register_or_get_by_email(conf, email)
      assert user.email == email
      assert is_nil(user.confirmed_at)
    end
  end

  describe "change_user_registration/2" do
    test "returns a changeset", %{conf: conf} do
      assert %Ecto.Changeset{} = changeset = Users.change_user_registration(struct(conf.user))
      assert changeset.required == [:email]
    end

    test "allows fields to be set", %{conf: conf} do
      email = unique_user_email()

      changeset =
        Users.change_user_registration(
          struct(conf.user),
          valid_user_attributes(email: email)
        )

      assert changeset.valid?
      assert get_change(changeset, :email) == email
    end
  end

  describe "change_user_email/2" do
    test "returns a user changeset", %{conf: conf} do
      assert %Ecto.Changeset{} = changeset = Users.change_user_email(struct(conf.user))
      assert changeset.required == [:email]
    end
  end

  describe "apply_user_email/3" do
    setup %{conf: conf} do
      %{user: user_fixture(conf)}
    end

    test "requires email to change", %{user: user} do
      {:error, changeset} = Users.apply_user_email(user, %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{user: user} do
      {:error, changeset} = Users.apply_user_email(user, %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{user: user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} = Users.apply_user_email(user, %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "applies the email without persisting it", %{user: user, conf: conf} do
      email = unique_user_email()
      {:ok, user} = Users.apply_user_email(user, %{email: email})
      assert user.email == email
      assert Users.get_user!(conf, user.id).email != email
    end
  end

  describe "deliver_update_email_instructions/3" do
    setup %{conf: conf} do
      %{user: user_fixture(conf)}
    end

    test "sends token through notification", %{user: user, conf: conf} do
      token =
        extract_user_token(fn url ->
          Users.deliver_update_email_instructions(conf, user, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(conf.token, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "change:current@example.com"
    end
  end

  describe "update_user_email/2" do
    setup %{conf: conf} do
      user = user_fixture(conf)
      email = unique_user_email()

      token =
        extract_user_token(fn url ->
          Users.deliver_update_email_instructions(conf, %{user | email: email}, user.email, url)
        end)

      %{user: user, token: token, email: email}
    end

    test "updates the email with a valid token", %{
      user: user,
      token: token,
      email: email,
      conf: conf
    } do
      assert Users.update_user_email(conf, user, token) == :ok
      changed_user = Repo.get!(conf.user, user.id)
      assert changed_user.email != user.email
      assert changed_user.email == email
      assert changed_user.confirmed_at
      assert changed_user.confirmed_at != user.confirmed_at
      refute Repo.get_by(conf.token, user_id: user.id)
    end

    test "does not update email with invalid token", %{user: user, conf: conf} do
      assert Users.update_user_email(conf, user, "oops") == :error
      assert Repo.get!(conf.user, user.id).email == user.email
      assert Repo.get_by(conf.token, user_id: user.id)
    end

    test "does not update email if user email changed", %{user: user, token: token, conf: conf} do
      assert Users.update_user_email(conf, %{user | email: "current@example.com"}, token) ==
               :error

      assert Repo.get!(conf.user, user.id).email == user.email
      assert Repo.get_by(conf.token, user_id: user.id)
    end

    test "does not update email if token expired", %{user: user, token: token, conf: conf} do
      {1, nil} = Repo.update_all(conf.token, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Users.update_user_email(conf, user, token) == :error
      assert Repo.get!(conf.user, user.id).email == user.email
      assert Repo.get_by(conf.token, user_id: user.id)
    end
  end

  describe "generate_user_session_token/1" do
    setup %{conf: conf} do
      %{user: user_fixture(conf)}
    end

    test "generates a token", %{user: user, conf: conf} do
      token = Users.generate_user_session_token(conf, user)
      assert user_token = Repo.get_by(conf.token, token: token)
      assert user_token.context == "session"

      # Creating the same token for another user should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(
          struct!(conf.token,
            token: user_token.token,
            user_id: user_fixture(conf).id,
            context: "session"
          )
        )
      end
    end
  end

  describe "get_user_by_session_token/1" do
    setup %{conf: conf} do
      user = user_fixture(conf)
      token = Users.generate_user_session_token(conf, user)
      %{user: user, token: token}
    end

    test "returns user by token", %{user: user, token: token, conf: conf} do
      assert session_user = Users.get_user_by_session_token(conf, token)
      assert session_user.id == user.id
    end

    test "does not return user for invalid token", %{conf: conf} do
      refute Users.get_user_by_session_token(conf, "oops")
    end

    test "does not return user for expired token", %{token: token, conf: conf} do
      {1, nil} = Repo.update_all(conf.token, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Users.get_user_by_session_token(conf, token)
    end
  end

  describe "delete_session_token/1" do
    test "deletes the token", %{conf: conf} do
      user = user_fixture(conf)
      token = Users.generate_user_session_token(conf, user)
      assert Users.delete_session_token(conf, token) == :ok
      refute Users.get_user_by_session_token(conf, token)
    end
  end

  describe "deliver_user_confirmation_instructions/2" do
    setup %{conf: conf} do
      %{user: user_fixture(conf)}
    end

    test "sends token through notification", %{user: user, conf: conf} do
      token =
        extract_user_token(fn url ->
          Users.deliver_user_confirmation_instructions(conf, user, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(conf.token, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "confirm"
    end
  end

  describe "deliver_magic_link_instructions/2" do
    setup %{conf: conf} do
      %{user: user_fixture(conf)}
    end

    test "sends token through notification", %{user: user, conf: conf} do
      token =
        extract_user_token(fn url ->
          Users.deliver_magic_link_instructions(conf, user, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(conf.token, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "magic"
    end
  end

  describe "confirm_user/1" do
    setup %{conf: conf} do
      user = user_fixture(conf)

      token =
        extract_user_token(fn url ->
          Users.deliver_magic_link_instructions(conf, user, url)
        end)

      %{user: user, token: token}
    end

    test "confirms the email with a valid token", %{user: user, token: token, conf: conf} do
      assert {:ok, confirmed_user} = Users.confirm_user(conf, token)
      assert confirmed_user.confirmed_at
      assert confirmed_user.confirmed_at != user.confirmed_at
      assert Repo.get!(conf.user, user.id).confirmed_at
      refute Repo.get_by(conf.token, user_id: user.id)
    end

    test "does not confirm with invalid token", %{user: user, conf: conf} do
      assert Users.confirm_user(conf, "oops") == :error
      refute Repo.get!(conf.user, user.id).confirmed_at
      assert Repo.get_by(conf.token, user_id: user.id)
    end

    test "does not confirm email if token expired", %{user: user, token: token, conf: conf} do
      {1, nil} = Repo.update_all(conf.token, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Users.confirm_user(conf, token) == :error
      refute Repo.get!(conf.user, user.id).confirmed_at
      assert Repo.get_by(conf.token, user_id: user.id)
    end
  end
end
