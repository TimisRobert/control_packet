defmodule StarflareMqtt.ControlPacket.Unsuback do
  @moduledoc false

  defstruct [:packet_identifier, :reason_codes, :properties]
end
