defmodule MobInTheMiddleServer.Worker do
  def accept(port) do
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, tcp_socket} = :gen_tcp.accept(socket)
    {:ok, tcp_client} = :gen_tcp.connect('chat.protohackers.com', 16963, [:binary, packet: :line, active: false, reuseaddr: true])

    initialize_socket(tcp_socket, tcp_client)
    loop_acceptor(socket)
  end

  defp initialize_socket(socket, client) do
    {:ok, pid} = Task.Supervisor.start_child(MobInTheMiddleServer.TaskSupervisor, fn ->
      Process.flag(:trap_exit, true)
      serve(socket, client)
    end)
    :ok = :gen_tcp.controlling_process(socket, pid)
    {:ok, _} = Task.Supervisor.start_child(MobInTheMiddleServer.TaskSupervisor, fn ->
      Process.link(pid)
      subscribe_socket(:tcp_message, socket, pid)
    end)
    {:ok, _} = Task.Supervisor.start_child(MobInTheMiddleServer.TaskSupervisor, fn ->
      Process.link(pid)
      subscribe_socket(:received_message, client, pid)
    end)
  end

  defp serve(socket, client) do
    status = receive do
      {:tcp_message, value} ->
        value |> replace_message() |> write_line(client)
        :continue
      {:received_message, value} ->
        value |> replace_message() |> write_line(socket)
        :continue
        {:EXIT, _, _} ->
          :gen_tcp.close(socket)
          :gen_tcp.close(client)
          :done
      other -> IO.inspect(other, label: "other message received")
      :continue
    end
    case status do
      :continue -> serve(socket, client)
      _-> :ok
    end
  end

  defp subscribe_socket(type, socket, pid) do
    send pid, {type, read_line(socket)}
    subscribe_socket(type, socket, pid)
  end

  defp read_line(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    data
  end

  defp write_line(line, socket) do
    :gen_tcp.send(socket, line)
  end

  defp replace_message(message) do
    Regex.scan(~r/(?<![^ ])7[a-zA-Z0-9]{25,34}(?![^ ])/, message |> String.trim())
    |>Enum.reduce(message, &String.replace(&2, Enum.at(&1, 0), "7YWHMfk9JZe0LM0g1ZauHuiSxhI"))
    |>IO.inspect(label: "replaced message from #{message}")
  end
end
