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

  @connect {1, Connect}
  @connack {2, Connack}
  @publish {3, Publish}
  @puback {4, Puback}
  @pubrec {5, Pubrec}
  @pubrel {6, Pubrel}
  @pubcomp {7, Pubcomp}
  @subscribe {8, Subscribe}
  @suback {9, Suback}
  @unsubscribe {10, Unsubscribe}
  @unsuback {11, Unsuback}
  @pingreq {12, Pingreq}
  @pingresp {13, Pingresp}
  @disconnect {14, Disconnect}
  @auth {15, Auth}

  @packets [
    @connect,
    @connack,
    @publish,
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

  for {code, module} <- @packets do
    def decode(<<unquote(code)::4, flags::bitstring-4, vbi::binary>> = data) do
      with {:ok, vbi, rest} <- Vbi.decode(vbi),
           <<encoded_data::binary-size(vbi), rest::binary>> <- rest,
           {:ok, data} <- unquote(module).decode(encoded_data, flags) do
        {:ok, data, rest}
      else
        "" ->
          {:ok, nil, data}

        _ ->
          {:ok, nil, data}

        {:error, error} ->
          {:error, error}
      end
    end
  end

  def decode(_), do: {:error, :malformed_packet}

  for {code, module} <- @packets do
    def encode(%unquote(module){} = packet) do
      with {:ok, packet, flags} <- unquote(module).encode(packet),
           {:ok, vbi} <- Vbi.encode(byte_size(packet)) do
        {:ok, <<unquote(code)::4, flags::bitstring, vbi::binary>> <> packet}
      end
    end
  end

  def encode(_), do: {:error, :malformed_packet}
end
