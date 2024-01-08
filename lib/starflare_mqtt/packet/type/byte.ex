defmodule StarflareMqtt.Packet.Type.Byte do
  @moduledoc false

  def decode(<<data, rest::binary>>), do: {:ok, data, rest}
  def decode(_), do: {:error, :decode_error}

  def encode(data), do: {:ok, <<data>>}
end
