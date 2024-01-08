defmodule StarflareMqtt.Packet.Type.Vbi do
  @moduledoc false
  require Logger

  import Bitwise

  def skip(<<0::1, _::7, rest::binary>>), do: {:ok, rest}
  def skip(<<_, 0::1, _::7, rest::binary>>), do: {:ok, rest}
  def skip(<<_, _, 0::1, _::7, rest::binary>>), do: {:ok, rest}
  def skip(<<_, _, _, 0::1, _::7, rest::binary>>), do: {:ok, rest}
  def skip(_), do: {:error, :decode_error}

  def decode(data), do: decode(data, 1, 0)

  defp decode(<<0::1, num::7, rest::binary>>, multiplier, total) do
    {:ok, total + num * multiplier, rest}
  end

  defp decode(<<1::1, num::7, rest::binary>>, multiplier, total) do
    decode(rest, multiplier * 128, total + num * multiplier)
  end

  defp decode(_, _, _), do: {:error, :decode_error}

  def encode(integer), do: encode(integer, <<>>)
  defp encode(0, data), do: {:ok, data}

  defp encode(integer, data) do
    encoded_byte = integer &&& 127
    integer = integer >>> 7

    if integer > 0 do
      encode(integer, data <> <<encoded_byte ||| 128>>)
    else
      encode(integer, data <> <<encoded_byte>>)
    end
  end
end
