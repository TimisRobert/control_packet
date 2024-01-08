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
      Publish.decode(data, flags)
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

  def encode(%Connect{} = connect) do
    with {:ok, packet} <- Connect.encode(connect),
         {:ok, vbi} <- Vbi.encode(byte_size(packet)) do
      <<@connect::4, 0::4, vbi::binary>> <> packet
    end
  end
end
