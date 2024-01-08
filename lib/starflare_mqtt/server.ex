defmodule StarflareMqtt.Server do
  @moduledoc false
  alias StarflareMqtt.Packet.Connack

  require Logger

  def start() do
    {:ok, socket} = :gen_tcp.listen(1883, [:binary, packet: :raw, active: false, reuseaddr: true])
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, data} = :gen_tcp.recv(client, 0)

    {:ok, command} = StarflareMqtt.Packet.decode(data)
    Logger.info("first packet: #{inspect(command)}")

    {:ok, connack} =
      StarflareMqtt.Packet.encode(%Connack{
        session_present: false,
        reason_code: :success
      })

    with :ok <- :gen_tcp.send(client, connack),
         {:ok, data} <- :gen_tcp.recv(client, 0) do
      Logger.info("raw second packet: #{inspect(data)}")
      {:ok, command} = StarflareMqtt.Packet.decode(data)
      Logger.info("second packet: #{inspect(command)}")

      {:ok, command} = StarflareMqtt.Packet.encode(command)
      Logger.info("second packet re encoded: #{inspect(command)}")

      {:ok, command} = StarflareMqtt.Packet.decode(command)
      Logger.info("second packet re decoded: #{inspect(command)}")
    end

    with {:ok, data} <- :gen_tcp.recv(client, 0) do
      Logger.info("raw third packet: #{inspect(data)}")
      {:ok, command} = StarflareMqtt.Packet.decode(data)
      Logger.info("third packet: #{inspect(command)}")
    end

    :gen_tcp.close(client)
    :gen_tcp.close(socket)
  end
end
