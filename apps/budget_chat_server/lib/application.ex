defmodule BudgetChatServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    port = Application.fetch_env!(:budget_chat_server, :port)

    children = [
      {Phoenix.PubSub, name: BudgetChatServer.PubSub},
      {BudgetChatServer.Tracker, name: BudgetChatServer.Tracker},
      {Task.Supervisor, name: BudgetChatServer.TaskSupervisor},
      {Task, fn -> BudgetChatServer.Worker.accept(port) end}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BudgetChatServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
