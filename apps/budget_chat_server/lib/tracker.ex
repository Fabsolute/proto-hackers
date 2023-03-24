defmodule BudgetChatServer.Tracker do
  use Phoenix.Tracker

  def start_link(opts) do
    opts = Keyword.merge([name: __MODULE__], opts)
      |>Keyword.put(:pubsub_server, BudgetChatServer.PubSub)
    Phoenix.Tracker.start_link(__MODULE__, opts, opts)
  end

  @impl true
  def init(opts) do
    server = Keyword.get(opts, :pubsub_server)
    {:ok, %{pubsub_server: server, node_name: Phoenix.PubSub.node_name(server)}}
  end

  @impl true
  def handle_diff(diff, state) do
    for {topic, {joins, leaves}} <- diff do
      for {key, meta} <- joins do
        msg = {:join, key, meta}
        Phoenix.PubSub.direct_broadcast!(state.node_name, state.pubsub_server, topic, msg)
      end

      for {key, meta} <- leaves do
        msg = {:leave, key, meta}
        Phoenix.PubSub.direct_broadcast!(state.node_name, state.pubsub_server, topic, msg)
      end
    end
    {:ok, state}
  end

  def track(name, username, state) do
    BudgetChatServer.PubSub.subscribe(name)
    Phoenix.Tracker.track(__MODULE__, self(), name, username, state)
  end

  def list(name) do
    Phoenix.Tracker.list(__MODULE__, name)
  end
end
