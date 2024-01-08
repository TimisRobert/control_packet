defmodule StarflareMqtt.Packet.Type.Utf8 do
  @moduledoc false

  def decode(<<length::16, data::binary-size(length), rest::binary>>),
    do: {:ok, to_string(data), rest}

  def decode(_), do: {:error, :decode_error}

  def encode(data) do
    {:ok, <<byte_size(data)::16, data::binary>>}
  end
end
