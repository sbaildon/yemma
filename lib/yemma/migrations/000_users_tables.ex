defmodule Yemma.Migrations.CreateUsersTables do
  use Ecto.Migration

  def change do
    execute(&maybe_ci_extension/0, "")

    create table(:users) do
      email(repo().__adapter__)
      add(:confirmed_at, :utc_datetime)
      timestamps()
    end

    create(unique_index(:users, [:email]))

    create table(:users_tokens) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:token, :binary, null: false)
      add(:context, :text, null: false)
      add(:sent_to, :text)
      timestamps(updated_at: false)
    end

    create(index(:users_tokens, [:user_id]))
    create(unique_index(:users_tokens, [:context, :token]))
  end

  defp maybe_ci_extension, do: repo() |> ci_for_adapter()

  defp ci_for_adapter(repo) do
    case repo.__adapter__ do
      Ecto.Adapters.Postgres ->
        repo.query!("CREATE EXTENSION IF NOT EXISTS citext")

      _ ->
        nil
    end
  end

  defp email(Ecto.Adapters.Postgres),
    do: add(:email, :citext, null: false, collate: :nocase)

  defp email(Ecto.Adapters.SQLite3),
    do: add(:email, :text, null: false, collate: :nocase)
end
