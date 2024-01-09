defmodule StarflareMqtt.Type.TwoByte do
  @moduledoc false

  def decode(<<data::16, rest::binary>>), do: {:ok, data, rest}
  def decode(_), do: {:error, :malformed_packet}

  def encode(data), do: {:ok, <<data::16>>}
end
