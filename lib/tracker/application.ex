defmodule Tracker.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Tracker.Worker.start_link(arg)
      # {Tracker.Worker, arg}
      {DynamicSupervisor, name: Tracker.SummonerSupervisor, strategy: :one_for_one},
      {Registry, [keys: :unique, name: :summoner_registry]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Tracker.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
