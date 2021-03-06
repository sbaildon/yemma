defmodule Yemma.Users.UserToken do
  use Ecto.Schema
  import Ecto.Query

  @hash_algorithm :sha256
  @rand_size 32

  @magic_validity {10, "minute"}
  @change_email_validiity {7, "day"}
  @session_validity {60, "day"}

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      use Ecto.Schema

      @primary_key Keyword.get(opts, :primary_key, nil)
      @foreign_key_type Keyword.get(opts, :foreign_key_type, :id)

      schema "users_tokens" do
        field :token, :binary
        field :context, :string
        field :sent_to, :string
        field :user_id, @foreign_key_type

        timestamps(updated_at: false)
      end
    end
  end

  @doc """
  Generates a token that will be stored in a signed place,
  such as session or cookie. As they are signed, those
  tokens do not need to be hashed.

  The reason why we store session tokens in the database, even
  though Phoenix already provides a session cookie, is because
  Phoenix' default session cookies are not persisted, they are
  simply signed and potentially encrypted. This means they are
  valid indefinitely, unless you change the signing/encryption
  salt.

  Therefore, storing them allows individual user
  sessions to be expired. The token system can also be extended
  to store additional data, such as the device used for logging in.
  You could then use this information to display all valid sessions
  and devices in the UI and allow users to explicitly expire any
  session they deem invalid.
  """
  def build_session_token(conf, user) do
    token = :crypto.strong_rand_bytes(@rand_size)
    {token, struct!(conf.token, token: token, context: "session", user_id: user.id)}
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the user found by the token, if any.

  The token is valid if it matches the value in the database and it has
  not expired (after @session_validity_in_days).
  """
  def verify_session_token_query(conf, token) do
    {duration, unit} = validity_for_context("session")

    query =
      from token in token_and_context_query(conf, token, "session"),
        join: user in ^conf.user,
        on: user.id == token.user_id,
        where: token.inserted_at > ago(^duration, ^unit),
        select: user

    {:ok, query}
  end

  @doc """
  Builds a token and its hash to be delivered to the user's email.

  The non-hashed token is sent to the user email while the
  hashed part is stored in the database. The original token cannot be reconstructed,
  which means anyone with read-only access to the database cannot directly use
  the token in the application to gain access. Furthermore, if the user changes
  their email in the system, the tokens sent to the previous email are no longer
  valid.

  Users can easily adapt the existing code to provide other types of delivery methods,
  for example, by phone numbers.
  """
  def build_email_token(conf, user, context) do
    build_hashed_token(conf, user, context, user.email)
  end

  defp build_hashed_token(conf, user, context, sent_to) do
    token = :crypto.strong_rand_bytes(@rand_size)
    hashed_token = :crypto.hash(@hash_algorithm, token)

    {Base.url_encode64(token, padding: false),
     struct!(conf.token,
       token: hashed_token,
       context: context,
       sent_to: sent_to,
       user_id: user.id
     )}
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the token found by the token, if any.

  The given token is valid if it matches its hashed counterpart in the
  database and the user email has not changed. This function also checks
  if the token is being used within a certain period, depending on the
  context. The default contexts supported by this function are either
  "confirm", for account confirmation emails . For verifying requests
  to change the email, see `verify_change_email_token_query/2`.
  """
  def verify_email_token_query(conf, token, context) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)
        {duration, unit} = validity_for_context(context)

        query =
          from token in token_and_context_query(conf, hashed_token, context),
            join: user in ^conf.user,
            on: user.id == token.user_id,
            where: token.inserted_at > ago(^duration, ^unit) and token.sent_to == user.email,
            select: {token, user}

        {:ok, query}

      :error ->
        :error
    end
  end

  defp validity_for_context("magic"), do: @magic_validity
  defp validity_for_context("session"), do: @session_validity
  defp validity_for_context("change:" <> _), do: @change_email_validiity

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the user found by the token, if any.

  This is used to validate requests to change the user
  email. It is different from `verify_email_token_query/2` precisely because
  `verify_email_token_query/2` validates the email has not changed, which is
  the starting point by this function.

  The given token is valid if it matches its hashed counterpart in the
  database and if it has not expired (after @change_email_validity_in_days).
  The context must always start with "change:".
  """
  def verify_change_email_token_query(conf, token, "change:" <> _ = context) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)
        {duration, unit} = validity_for_context(context)

        query =
          from token in token_and_context_query(conf, hashed_token, context),
            where: token.inserted_at > ago(^duration, ^unit)

        {:ok, query}

      :error ->
        :error
    end
  end

  @doc """
  Returns the token struct for the given token value and context.
  """
  def token_and_context_query(conf, token, context) do
    from conf.token, where: [token: ^token, context: ^context]
  end

  @doc """
  Gets all tokens for the given user for the given contexts.
  """
  def user_and_contexts_query(conf, user, :all) do
    from t in conf.token, where: t.user_id == ^user.id
  end

  def user_and_contexts_query(conf, user, [_ | _] = contexts) do
    from t in conf.token, where: t.user_id == ^user.id and t.context in ^contexts
  end
end
