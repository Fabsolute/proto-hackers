defmodule MeansToEndServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    port = Application.fetch_env!(:means_to_end_server, :port)

    children = [
      {Task.Supervisor, name: MeansToEndServer.TaskSupervisor},
      {Task, fn -> MeansToEndServer.Worker.accept(port) end}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MeansToEndServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
