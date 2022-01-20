defmodule Yemma do
  @moduledoc """
  Yemma keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  use GenServer

  alias Yemma.Config

  def start_link(opts) do
    conf = Config.new(opts)
    GenServer.start_link(__MODULE__, conf, name: __MODULE__)
  end

  @impl true
  def init(conf) do
    {:ok, conf}
  end

  @impl true
  def handle_call(:config, _from, conf) do
    {:reply, conf, conf}
  end

  def config() do
    GenServer.call(Yemma, :config)
  end
end
