defmodule Yemma do
  @moduledoc """
  Yemma keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def child_spec(opts) do
    opts
    |> super()
    |> Supervisor.child_spec(id: Keyword.get(opts, :name, __MODULE__))
  end

  def init(_opts) do
    children = [
      YemmaWeb.Telemetry
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
