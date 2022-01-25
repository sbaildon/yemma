defmodule Yemma.Users.User do
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      use Ecto.Schema
      import Ecto.Changeset

      @primary_key Keyword.get(opts, :primary_key)
      @foreign_key_type Keyword.get(opts, :foreign_key_type, :id)

      schema "users" do
        field :email, :string
        field :confirmed_at, :naive_datetime

        timestamps()
      end

      @doc """
      A user changeset for registration.

      It is important to validate the length of email addresses.
      Otherwise databases may truncate the email without warnings, which
      could lead to unpredictable or insecure behaviour.

      """
      def registration_changeset(user, attrs, _opts \\ []) do
        user
        |> cast(attrs, [:email])
        |> validate_email()
      end

      defp validate_email(changeset) do
        changeset
        |> validate_required([:email])
        |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/,
          message: "must have the @ sign and no spaces"
        )
        |> validate_length(:email, max: 160)
        |> unique_constraint(:email)
      end

      @doc """
      A user changeset for changing the email.

      It requires the email to change otherwise an error is added.
      """
      def email_changeset(user, attrs) do
        user
        |> cast(attrs, [:email])
        |> validate_email()
        |> case do
          %{changes: %{email: _}} = changeset -> changeset
          %{} = changeset -> add_error(changeset, :email, "did not change")
        end
      end

      @doc """
      Confirms the account by setting `confirmed_at`.
      """
      def confirm_changeset(user) do
        now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        change(user, confirmed_at: now)
      end
    end
  end
end
