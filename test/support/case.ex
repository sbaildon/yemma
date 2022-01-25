defmodule Yemma.Case do
  import ExUnit.Callbacks, only: [start_supervised!: 1]

  alias Yemma.Config

  def start_supervised_yemma!(), do: start_supervised_yemma!([])

  def start_supervised_yemma!(opts) do
    start_supervised!({Yemma, yemma_opts(opts)})
    |> Yemma.config()
  end

  def yemma_opts(), do: yemma_opts([])

  def yemma_opts(opts) do
    opts
    |> Keyword.put_new(:routes, Phoenix.YemmaTest.Router.Helpers)
    |> Keyword.put_new(:secret_key_base, random_string(64))
    |> Keyword.put_new(:repo, YemmaTest.Repo)
    |> Keyword.put_new(:user, Phoenix.YemmaTest.User)
  end

  def yemma_config(), do: yemma_opts() |> Config.new()
  def yemma_config(opts), do: yemma_opts(opts) |> Config.new()

  defp random_string(length) when length > 31 do
    :crypto.strong_rand_bytes(length) |> Base.encode64(padding: false) |> binary_part(0, length)
  end

  defp random_string(_),
    do: raise(ArgumentError, "The secret should be at least 32 characters long")
end
