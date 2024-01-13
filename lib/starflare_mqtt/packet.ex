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

  @connect {1, 0, Connect}
  @connack {2, 0, Connack}
  @puback {4, 0, Puback}
  @pubrec {5, 0, Pubrec}
  @pubrel {6, 2, Pubrel}
  @pubcomp {7, 0, Pubcomp}
  @subscribe {8, 2, Subscribe}
  @suback {9, 0, Suback}
  @unsubscribe {10, 2, Unsubscribe}
  @unsuback {11, 0, Unsuback}
  @pingreq {12, 0, Pingreq}
  @pingresp {13, 0, Pingresp}
  @disconnect {14, 0, Disconnect}
  @auth {15, 0, Auth}

  @packets [
    @connect,
    @connack,
    @puback,
    @pubrec,
    @pubrel,
    @pubcomp,
    @subscribe,
    @suback,
    @unsubscribe,
    @unsuback,
    @pingreq,
    @pingresp,
    @disconnect,
    @auth
  ]

  for {code, rest, module} <- @packets do
    def decode(<<unquote(code)::4, unquote(rest)::4, vbi::binary>> = data) do
      with {:ok, vbi, rest} <- Vbi.decode(vbi),
           <<data::binary-size(vbi), rest::binary>> <- rest,
           {:ok, data} <- unquote(module).decode(data) do
        {:ok, data, rest}
      else
        "" ->
          {:ok, nil, data}

        error ->
          {:error, error}
      end
    end
  end

  def decode(<<3::4, flags::bitstring-4, vbi::binary>>) do
    with {:ok, vbi, rest} <- Vbi.decode(vbi) do
      <<data::binary-size(vbi), rest::binary>> = rest

      with {:ok, data} <- Publish.decode(data, flags) do
        {:ok, data, rest}
      end
    end
  end

  def decode(_), do: {:error, :malformed_packet}

  for {code, rest, module} <- @packets do
    def encode(%unquote(module){} = packet) do
      with {:ok, packet} <- unquote(module).encode(packet),
           {:ok, vbi} <- Vbi.encode(byte_size(packet)) do
        {:ok, <<unquote(code)::4, unquote(rest)::4, vbi::binary>> <> packet}
      end
    end
  end

  def encode(%Publish{} = publish) do
    with {:ok, packet, flags} <- Publish.encode(publish),
         {:ok, vbi} <- Vbi.encode(byte_size(packet)) do
      {:ok, <<3::4, flags::bitstring, vbi::binary>> <> packet}
    end
  end
end
