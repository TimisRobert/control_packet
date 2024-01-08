defmodule StarflareMqtt.Packet.Type.FourByte do
  @moduledoc false

  def decode(<<data::32, rest::binary>>), do: {:ok, data, rest}
  def decode(_), do: {:error, :malformed_packet}

  def encode(data), do: {:ok, <<data::32>>}
end
