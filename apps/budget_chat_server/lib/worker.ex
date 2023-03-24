defmodule BudgetChatServer.Worker do
  alias BudgetChatServer.{Tracker, PubSub}

  def accept(port) do
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(BudgetChatServer.TaskSupervisor, fn -> serve(client, nil, :init) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  defp serve(socket, nil, :init) do
    write_line("Welcome to budgetchat! What shall I call you?\n", socket)

    read_line(socket)
    |> handle_join(socket)
  end

  defp serve(socket,username, :chat) do
    receive do
      {:tcp_message, value} ->
        PubSub.broadcast("chat", {:message, self(), "[#{username}] #{value}"})
      {:message, sender, value} ->
        if sender != self() do
          write_line(value, socket)
        end
      {:join, key, %{pid: pid}} ->
        if pid != self() do
          write_line("* #{key} has entered the room\n", socket)
        end
      {:leave, key, %{pid: pid}} ->
        if pid != self() do
          write_line("* #{key} has left the room\n", socket)
        end
      other -> IO.inspect(other, label: "other message received")
    end

    serve(socket, username, :chat)
  end

  defp handle_join(name, socket) when is_bitstring(name) do
    name = String.slice(name, 0, String.length(name) - 1)
    if Regex.match?(~r/^[a-zA-Z0-9]+$/, name) do
      users =
        Tracker.list("users")
        |>Enum.map(fn {username,_} -> username end)
        |>Enum.join(", ")
      write_line("* The room contains: #{users}\n", socket)
      Tracker.track("users", name, %{pid: self()})
      PubSub.subscribe("chat")
      pid = self()
      spawn_link(fn -> subscribe_socket(socket, pid) end)
      serve(socket, name, :chat)
    else
      write_line("The username is not allowed", socket)
      :gen_tcp.close(socket)
    end
  end

  defp subscribe_socket(socket, pid) do
    send pid, {:tcp_message, read_line(socket)}
    subscribe_socket(socket, pid)
  end

  defp read_line(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    data
  end

  defp write_line(line, socket) do
    :gen_tcp.send(socket, line)
  end
end
