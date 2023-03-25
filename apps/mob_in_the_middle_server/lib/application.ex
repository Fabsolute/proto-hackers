defmodule MobInTheMiddleServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    port = Application.fetch_env!(:mob_in_the_middle_server, :port)

    children = [
      {Task.Supervisor, name: MobInTheMiddleServer.TaskSupervisor},
      {Task, fn -> MobInTheMiddleServer.Worker.accept(port) end}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MobInTheMiddleServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
