defmodule StarflareMqtt.ControlPacket.Publish do
  @moduledoc false

  @enforce_keys [:topic_name, :packet_identifier]
  defstruct dup_flag: false,
            qos_level: :at_most_once,
            retain: false,
            topic_name: nil,
            packet_identifier: nil,
            properties: [],
            payload: nil
end
