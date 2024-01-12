defmodule StarflareMqtt.Packet.Type.Qos do
  @moduledoc false

  @at_most_once 0
  @at_least_once 1
  @exactly_once 2

  def decode(<<data::2, rest::bitstring>>) do
    case data do
      @at_most_once -> {:ok, :at_most_once, rest}
      @at_least_once -> {:ok, :at_least_once, rest}
      @exactly_once -> {:ok, :exactly_once, rest}
      _ -> {:error, :malformed_packet, rest}
    end
  end

  def encode(qos) do
    case qos do
      :at_most_once -> {:ok, <<@at_most_once>>}
      :at_least_once -> {:ok, <<@at_least_once>>}
      :exactly_once -> {:ok, <<@exactly_once>>}
      _ -> {:error, :malformed_packet}
    end
  end
end
