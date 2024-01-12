defmodule StarflareMqtt.Packet.Type.Utf8Pair do
  @moduledoc false

  def decode(<<
        key_length::16,
        key_data::binary-size(key_length),
        value_length::16,
        value_data::binary-size(value_length),
        rest::binary
      >>) do
    {:ok, {to_string(key_data), to_string(value_data)}, rest}
  end

  def decode(_), do: {:error, :malformed_packet}

  def encode({key, value}) do
    {:ok, <<byte_size(key)::16, key::binary, byte_size(value)::16, value::binary>>}
  end
end
