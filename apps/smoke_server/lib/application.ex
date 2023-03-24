defmodule SmokeServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    port = Application.fetch_env!(:smoke_server, :port)

    children = [
      {Task.Supervisor, name: SmokeServer.TaskSupervisor},
      # Starts a worker by calling: SmokeServer.Worker.start_link(arg)
      {Task, fn -> SmokeServer.Worker.accept(port) end}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SmokeServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
