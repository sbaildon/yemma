defmodule Yemma.Test.Repo do
  use Ecto.Repo,
    otp_app: :yemma,
    adapter: Ecto.Adapters.SQLite3
end
