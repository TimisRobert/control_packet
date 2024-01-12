defmodule StarflareMqtt.Packet.Type.Boolean do
  @moduledoc false

  def decode(<<integer::1, rest::bitstring>>), do: {:ok, integer == 1, rest}

  def encode(true), do: {:ok, <<1::1>>}
  def encode(false), do: {:ok, <<0::1>>}
end
