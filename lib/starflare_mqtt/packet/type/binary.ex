defmodule StarflareMqtt.Packet.Type.Binary do
  @moduledoc false

  def decode(<<length::16, data::binary-size(length), rest::binary>>) do
    {:ok, data, rest}
  end

  def decode(_), do: {:error, :malformed_packet}

  def encode(data), do: {:ok, <<byte_size(data)::16, data::binary>>}
end
