import Config

config :yemma, YemmaTest.Repo,
  priv: "test/support/",
  url: System.fetch_env!("DATABASE_URL"),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox,
  migration_primary_key: [type: :string]

config :yemma,
  repo: YemmaTest.Repo,
  ecto_repos: [YemmaTest.Repo],
  pubsub_server: Phoenix.YemmaTest.PubSub,
  secret_key_base: "KGZHtZ5nYiaNleW9fCWoCjnAfRHY7gTl7S2+pzLKIN0paXk0Syv3826nJqdR/uiD",
  user: Phoenix.YemmaTest.User,
  token: Phoenix.YemmaTest.UserToken

# In test we don't send emails.
config :yemma, Yemma.Mailer, adapter: Swoosh.Adapters.Test

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :swoosh, :api_client, false

config :logger, :console, format: "$time $metadata[$level] $message\n", level: :warn
