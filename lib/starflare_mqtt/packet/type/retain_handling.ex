defmodule StarflareMqtt.Packet.Type.RetainHandling do
  @moduledoc false

  @send_when_subscribed 0
  @send_if_no_subscription 1
  @dont_send 2

  def decode(<<integer::2, rest::bitstring>>) do
    case integer do
      @send_when_subscribed -> {:ok, :send_when_subscribed, rest}
      @send_if_no_subscription -> {:ok, :send_if_no_subscription, rest}
      @dont_send -> {:ok, :dont_send, rest}
      _ -> {:error, :protocol_error}
    end
  end

  def encode(data) do
    case data do
      :send_when_subscribed -> {:ok, <<@send_when_subscribed::2>>}
      :send_if_no_subscription -> {:ok, <<@send_if_no_subscription::2>>}
      :dont_send -> {:ok, <<@dont_send::2>>}
      _ -> {:error, :protocol_error}
    end
  end
end
