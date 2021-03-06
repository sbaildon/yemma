defmodule Yemma.Users do
  @moduledoc """
  The Users context.
  """

  import Ecto.Query, warn: false

  alias Yemma.Users.UserToken
  alias Yemma.Config
  alias Yemma.Notifier

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(%Config{} = conf, email) when is_binary(email) do
    conf.repo.get_by(conf.user, email: email)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(%Config{} = conf, id), do: conf.repo.get!(conf.user, id)

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(%Config{} = conf, attrs) do
    struct(conf.user)
    |> Yemma.Users.User.registration_changeset(attrs)
    |> conf.repo.insert()
  end

  def register_or_get_by_email(conf, email) when is_binary(email) do
    user = get_user_by_email(conf, email)
    (user && {:ok, user}) || register_user(conf, %{"email" => email})
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(user, attrs \\ %{}) do
    Yemma.Users.User.registration_changeset(user, attrs)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}) do
    Yemma.Users.User.email_changeset(user, attrs)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_user_email(user, %{email: ...})
      {:ok, %User{}}

      iex> apply_user_email(user, %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_user_email(user, attrs) do
    user
    |> Yemma.Users.User.email_changeset(attrs)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_user_email(%Config{} = conf, user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(conf, token, context),
         %_{sent_to: email} <- conf.repo.one(query),
         {:ok, _} <- conf.repo.transaction(user_email_multi(conf, user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(conf, user, email, context) do
    changeset =
      user
      |> Yemma.Users.User.email_changeset(%{email: email})
      |> Yemma.Users.User.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(conf, user, [context]))
  end

  @doc """
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_update_email_instructions(user, current_email, &Routes.user_update_email_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_update_email_instructions(
        %Config{} = conf,
        user,
        current_email,
        update_email_url_fun
      )
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} =
      UserToken.build_email_token(conf, user, "change:#{current_email}")

    conf.repo.insert!(user_token)

    Notifier.deliver_update_email_instructions(
      conf,
      user,
      update_email_url_fun.(encoded_token)
    )
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(%Config{} = conf, user) do
    {token, user_token} = UserToken.build_session_token(conf, user)
    conf.repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(%Config{} = conf, token) do
    {:ok, query} = UserToken.verify_session_token_query(conf, token)
    conf.repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_session_token(%Config{} = conf, token) do
    conf.repo.delete_all(UserToken.token_and_context_query(conf, token, "session"))
    :ok
  end

  @doc """
  Delivers magic link email instructions to the given user.

  ## Examples

      iex> deliver_magic_link_instructions(user, &Routes.user_confirmation_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}
  """
  def deliver_magic_link_instructions(%Config{} = conf, user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(conf, user, "magic")
    conf.repo.insert!(user_token)

    Notifier.deliver_magic_link_instructions(
      conf,
      user,
      confirmation_url_fun.(encoded_token)
    )
  end

  @doc """
  Confirms a user by the given token.

  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  def confirm_user(%Config{} = conf, token) do
    with {:ok, query} <- UserToken.verify_email_token_query(conf, token, "magic"),
         {%{token: _} = user_token, %{email: _} = user} <- conf.repo.one(query),
         {:ok, %{user: user}} <-
           conf.repo.transaction(confirm_user_multi(user, user_token)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user, token) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, Yemma.Users.User.confirm_changeset(user))
    |> Ecto.Multi.delete(:token, token)
  end
end
