defmodule StarflareMqtt.Type.Utf8 do
  @moduledoc false

  def decode(<<length::16, data::binary-size(length), rest::binary>>),
    do: {:ok, to_string(data), rest}

  def decode(_), do: {:error, :malformed_packet}

  def encode(nil), do: {:ok, <<0::16>>}

  def encode(data) do
    {:ok, <<byte_size(data)::16, data::binary>>}
  end
end
