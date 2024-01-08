defmodule StarflareMqtt.Packet.Type.RetainHandling do
  @moduledoc false

  @send_when_subscribed 0
  @send_if_no_subscription 1
  @dont_send 2

  def decode(integer) do
    case integer do
      @send_when_subscribed -> {:ok, :send_when_subscribed}
      @send_if_no_subscription -> {:ok, :send_if_no_subscription}
      @dont_send -> {:ok, :dont_send}
      _ -> {:error, :protocol_error}
    end
  end

  def encode(data) do
    case data do
      :send_when_subscribed -> {:ok, @send_when_subscribed}
      :send_if_no_subscription -> {:ok, @send_if_no_subscription}
      :dont_send -> {:ok, @dont_send}
      _ -> {:error, :protocol_error}
    end
  end
end
