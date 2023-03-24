defmodule BudgetChatServer.PubSub do
  def subscribe(topic) do
    Phoenix.PubSub.subscribe(__MODULE__, topic)
  end

  def broadcast(topic, message) do
    Phoenix.PubSub.broadcast(__MODULE__, topic, message)
  end

  def direct_broadcast(topic, message) do
    node = Phoenix.PubSub.node_name(__MODULE__)
    Phoenix.PubSub.direct_broadcast!(node, __MODULE__, topic, message)
  end
end
