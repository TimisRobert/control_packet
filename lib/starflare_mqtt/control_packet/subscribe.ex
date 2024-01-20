defmodule StarflareMqtt.ControlPacket.Subscribe do
  @moduledoc false

  defstruct [:packet_identifier, :topic_filters, :properties]
end
