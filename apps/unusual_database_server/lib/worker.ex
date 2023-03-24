defmodule UnusualDatabaseServer.Worker do
  def accept(port) do
    {:ok, socket} =
      :gen_udp.open(port, [:binary])

    loop_acceptor(socket, %{})
  end

  defp loop_acceptor(socket, storage) do
    storage = receive do
      {:udp, ^socket, _host, _port, _bin} = msg ->
        handle_message(storage, msg)
      other-> IO.inspect(other, label: "other")
    end

    loop_acceptor(socket, storage)
  end

  defp handle_message(storage, msg) do
    {_, socket, host, port, bin} = msg

    packages = String.split(bin, "=")
    if length(packages) > 1 do
      store(storage, hd(packages), tl(packages) |> Enum.join("="))
    else
      data = retrive(storage, hd(packages))
      :gen_udp.send(socket, host, port, data)
      storage
    end
  end

  defp store(storage, key, value) do
    Map.put(storage,key, value)
  end

  defp retrive(_storage,"version") do
    "version=Ken's Key-Value Store 1.0"
  end

  defp retrive(storage, key) do
    "#{key}=#{Map.get(storage, key, "")}"
  end
end
