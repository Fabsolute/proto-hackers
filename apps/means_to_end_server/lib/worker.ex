defmodule MeansToEndServer.Worker do
  def accept(port) do
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :raw, active: false, reuseaddr: true])

    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(SmokeServer.TaskSupervisor, fn -> serve(client,[]) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  defp serve(socket, data) do
    data = case socket
    |> read_line()
    |> handle_request(data) do
      response when is_integer(response) ->
        write_line(response, socket)
        data
      data -> data
    end

    serve(socket, data)
  end

  defp handle_request(<<?I,timestamp::integer-signed-size(32),price::integer-signed-size(32)>>, data) do
    [{timestamp, price} | data]
  end

  defp handle_request(<<?Q,mintime::integer-signed-size(32),maxtime::integer-signed-size(32)>>, data) do
    {count,total} = mean_data(data, mintime, maxtime)
    if count == 0 do
      0
    else
      trunc(total/count)
    end
  end

  defp mean_data(data,mintime,maxtime) do
    data
    |>Enum.filter(fn {timestamp,_}->timestamp>=mintime and timestamp<=maxtime end)
    |>Enum.reduce({0,0},fn {_,price},{count,total}->{count+1,total+price} end)
  end

  defp read_line(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 9)
    data
  end

  defp write_line(line, socket) do
    line = <<line::integer-size(32)>>
    :gen_tcp.send(socket, line)
  end
end
