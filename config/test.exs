import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :yemma, Yemma.Test.Repo,
  priv: "test/support/",
  database: Path.expand("../yemma_test.db", Path.dirname(__ENV__.file)),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox

config :yemma,
  repo: Yemma.Test.Repo,
  pubsub_server: Phoenix.YemmaTest.PubSub,
  secret_key_base: "KGZHtZ5nYiaNleW9fCWoCjnAfRHY7gTl7S2+pzLKIN0paXk0Syv3826nJqdR/uiD"

# In test we don't send emails.
config :yemma, Yemma.Mailer, adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
