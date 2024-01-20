defmodule StarflareMqtt.ControlPacket.Unsubscribe do
  @moduledoc false

  defstruct [:packet_identifier, :topic_filters, :properties]
end
