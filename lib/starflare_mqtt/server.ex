defmodule StarflareMqtt.Server do
  @moduledoc false

  require Logger

  def start() do
    {:ok, socket} = :gen_tcp.listen(1883, [:binary, packet: :raw, active: false, reuseaddr: true])
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, data} = :gen_tcp.recv(client, 0)
    :gen_tcp.close(client)
    IO.inspect(data)
    StarflareMqtt.Packet.decode(data)
  end
end
