defmodule StarflareMqtt.Packet do
  @moduledoc false

  alias StarflareMqtt.Packet.{
    Connack,
    Connect,
    Publish,
    Puback,
    Pubrec,
    Pubrel,
    Pubcomp,
    Subscribe,
    Suback,
    Unsubscribe,
    Unsuback,
    Pingreq,
    Pingresp,
    Disconnect,
    Auth
  }

  alias StarflareMqtt.Packet.Type.Vbi

  @connect 1
  @connack 2
  @publish 3
  @puback 4
  @pubrec 5
  @pubrel 6
  @pubcomp 7
  @subscribe 8
  @suback 9
  @unsubscribe 10
  @unsuback 11
  @pingreq 12
  @pingresp 13
  @disconnect 14
  @auth 15

  def decode(<<@connect::4, _::4, vbi::binary>>) do
    with {:ok, data} <- Vbi.skip(vbi) do
      Connect.decode(data)
    end
  end

  def decode(<<@connack::4, _::4, vbi::binary>>) do
    with {:ok, data} <- Vbi.skip(vbi) do
      Connack.decode(data)
    end
  end

  def decode(<<@publish::4, flags::4, vbi::binary>>) do
    with {:ok, data} <- Vbi.skip(vbi) do
      Publish.decode(data, <<flags::4>>)
    end
  end

  def decode(<<@puback::4, _::4, vbi::binary>>) do
    with {:ok, data} <- Vbi.skip(vbi) do
      Puback.decode(data)
    end
  end

  def decode(<<@pubrec::4, _::4, vbi::binary>>) do
    with {:ok, data} <- Vbi.skip(vbi) do
      Pubrec.decode(data)
    end
  end

  def decode(<<@pubrel::4, 2::4, vbi::binary>>) do
    with {:ok, data} <- Vbi.skip(vbi) do
      Pubrel.decode(data)
    end
  end

  def decode(<<@pubcomp::4, _::4, vbi::binary>>) do
    with {:ok, data} <- Vbi.skip(vbi) do
      Pubcomp.decode(data)
    end
  end

  def decode(<<@subscribe::4, 2::4, vbi::binary>>) do
    with {:ok, data} <- Vbi.skip(vbi) do
      Subscribe.decode(data)
    end
  end

  def decode(<<@suback::4, _::4, vbi::binary>>) do
    with {:ok, data} <- Vbi.skip(vbi) do
      Suback.decode(data)
    end
  end

  def decode(<<@unsubscribe::4, 2::4, vbi::binary>>) do
    with {:ok, data} <- Vbi.skip(vbi) do
      Unsubscribe.decode(data)
    end
  end

  def decode(<<@unsuback::4, _::4, vbi::binary>>) do
    with {:ok, data} <- Vbi.skip(vbi) do
      Unsuback.decode(data)
    end
  end

  def decode(<<@pingreq::4, _::4, vbi::binary>>) do
    with {:ok, data} <- Vbi.skip(vbi) do
      Pingreq.decode(data)
    end
  end

  def decode(<<@pingresp::4, _::4, vbi::binary>>) do
    with {:ok, data} <- Vbi.skip(vbi) do
      Pingresp.decode(data)
    end
  end

  def decode(<<@disconnect::4, _::4, vbi::binary>>) do
    with {:ok, data} <- Vbi.skip(vbi) do
      Disconnect.decode(data)
    end
  end

  def decode(<<@auth::4, _::4, vbi::binary>>) do
    with {:ok, data} <- Vbi.skip(vbi) do
      Auth.decode(data)
    end
  end

  def decode(_), do: {:error, :malformed_packet}

  def encode(%Connect{} = connect) do
    with {:ok, packet} <- Connect.encode(connect),
         {:ok, vbi} <- Vbi.encode(byte_size(packet)) do
      {:ok, <<@connect::4, 0::4, vbi::binary>> <> packet}
    end
  end

  def encode(%Connack{} = connect) do
    with {:ok, packet} <- Connack.encode(connect),
         {:ok, vbi} <- Vbi.encode(byte_size(packet)) do
      {:ok, <<@connack::4, 0::4, vbi::binary>> <> packet}
    end
  end

  def encode(%Publish{} = connect) do
    with {:ok, packet, flags} <- Publish.encode(connect),
         {:ok, vbi} <- Vbi.encode(byte_size(packet)) do
      {:ok, <<@publish::4, flags::bitstring, vbi::binary>> <> packet}
    end
  end

  def encode(%Puback{} = connect) do
    with {:ok, packet} <- Puback.encode(connect),
         {:ok, vbi} <- Vbi.encode(byte_size(packet)) do
      {:ok, <<@puback::4, 0::4, vbi::binary>> <> packet}
    end
  end

  def encode(%Pubrec{} = connect) do
    with {:ok, packet} <- Pubrec.encode(connect),
         {:ok, vbi} <- Vbi.encode(byte_size(packet)) do
      {:ok, <<@pubrec::4, 0::4, vbi::binary>> <> packet}
    end
  end

  def encode(%Pubrel{} = connect) do
    with {:ok, packet} <- Pubrel.encode(connect),
         {:ok, vbi} <- Vbi.encode(byte_size(packet)) do
      {:ok, <<@pubrel::4, 2::4, vbi::binary>> <> packet}
    end
  end

  def encode(%Pubcomp{} = connect) do
    with {:ok, packet} <- Pubcomp.encode(connect),
         {:ok, vbi} <- Vbi.encode(byte_size(packet)) do
      {:ok, <<@pubcomp::4, 0::4, vbi::binary>> <> packet}
    end
  end

  def encode(%Subscribe{} = connect) do
    with {:ok, packet} <- Subscribe.encode(connect),
         {:ok, vbi} <- Vbi.encode(byte_size(packet)) do
      {:ok, <<@subscribe::4, 2::4, vbi::binary>> <> packet}
    end
  end

  def encode(%Suback{} = connect) do
    with {:ok, packet} <- Suback.encode(connect),
         {:ok, vbi} <- Vbi.encode(byte_size(packet)) do
      {:ok, <<@suback::4, 0::4, vbi::binary>> <> packet}
    end
  end

  def encode(%Unsubscribe{} = connect) do
    with {:ok, packet} <- Unsubscribe.encode(connect),
         {:ok, vbi} <- Vbi.encode(byte_size(packet)) do
      {:ok, <<@unsubscribe::4, 2::4, vbi::binary>> <> packet}
    end
  end

  def encode(%Pingreq{} = connect) do
    with {:ok, packet} <- Pingreq.encode(connect),
         {:ok, vbi} <- Vbi.encode(byte_size(packet)) do
      {:ok, <<@pingreq::4, 0::4, vbi::binary>> <> packet}
    end
  end

  def encode(%Pingresp{} = connect) do
    with {:ok, packet} <- Pingresp.encode(connect),
         {:ok, vbi} <- Vbi.encode(byte_size(packet)) do
      {:ok, <<@pingresp::4, 0::4, vbi::binary>> <> packet}
    end
  end

  def encode(%Auth{} = connect) do
    with {:ok, packet} <- Auth.encode(connect),
         {:ok, vbi} <- Vbi.encode(byte_size(packet)) do
      {:ok, <<@auth::4, 0::4, vbi::binary>> <> packet}
    end
  end
end
