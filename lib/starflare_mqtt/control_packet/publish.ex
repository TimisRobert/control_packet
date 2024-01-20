defmodule StarflareMqtt.ControlPacket.Publish do
  @moduledoc false

  defstruct [
    :dup_flag,
    :qos_level,
    :retain,
    :topic_name,
    :packet_identifier,
    :properties,
    :payload
  ]
end
