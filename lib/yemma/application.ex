defmodule Yemma.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      YemmaWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Yemma.PubSub},
      # Start the Endpoint (http/https)
      YemmaWeb.Endpoint
      # Start a worker by calling: Yemma.Worker.start_link(arg)
      # {Yemma.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Yemma.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
