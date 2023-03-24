defmodule PrimeTimeServer.Worker do
  def accept(port) do
    {:ok, socket} =
      :gen_tcp.listen(port, [mode: :binary, packet: :line, active: false, reuseaddr: true,buffer: 1024*100])

    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)

    {:ok, pid} =
      Task.Supervisor.start_child(PrimeTimeServer.TaskSupervisor, fn -> serve(client) end)

    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  defp serve(socket) do
    if socket
    |> read_line()
    |> decode_request()
    |> encode_response()
    |> write_line(socket) do

    serve(socket)
    end
  end

  defp read_line(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    data
  end

  defp decode_request(line) do
    case Jason.decode(line) do
      {:ok, %{"method" => "isPrime", "number" => number}} when is_number(number) ->
        %{"method" => "isPrime", "prime" => is_prime?(number)}

      _malformed ->
        :malformed
    end
  end

  defp encode_response(:malformed), do: :malformed

  defp encode_response(response) do
    (response |> Jason.encode!()) <> "\n"
  end

  defp write_line(line, socket) do
    case line do
      :malformed ->
        :gen_tcp.send(socket, "malformed")
        :gen_tcp.close(socket)
        false
        _->:gen_tcp.send(socket, line)
        true
    end
  end

  defp is_prime?(number) when is_float(number) or number < 2, do: false

  defp is_prime?(n) when n in [2, 3], do: true

  defp is_prime?(n) do
    not Enum.any?(2..trunc(:math.sqrt(n)), &(rem(n, &1) == 0))
  end
end
