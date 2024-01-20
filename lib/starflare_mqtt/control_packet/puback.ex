defmodule StarflareMqtt.ControlPacket.Puback do
  @moduledoc false

  defstruct [:packet_identifier, :reason_code, :properties]
end
