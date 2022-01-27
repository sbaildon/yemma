import Config

config :yemma, YemmaTest.Repo,
  priv: "test/support/",
  url: System.fetch_env!("DATABASE_URL"),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox,
  migration_primary_key: [type: :string]

# In test we don't send emails.
config :yemma, Yemma.Mailer, adapter: Swoosh.Adapters.Test

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :swoosh, :api_client, false

config :logger, :console, format: "$time $metadata[$level] $message\n", level: :warn
