defmodule StarflareMqtt.Packet.Type.Binary do
  @moduledoc false

  def decode(<<length::16, data::binary-size(length), rest::binary>>), do: {:ok, data, rest}
  def decode(_), do: {:error, :decode_error}

  def encode(data), do: {:ok, <<byte_size(data)::16, data::binary>>}
end
