defmodule StarflareMqtt.Type.Byte do
  @moduledoc false

  def decode(<<data, rest::binary>>), do: {:ok, data, rest}
  def decode(_), do: {:error, :malformed_packet}

  def encode(data), do: {:ok, <<data>>}
end
