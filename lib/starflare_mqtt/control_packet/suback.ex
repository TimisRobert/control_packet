defmodule StarflareMqtt.ControlPacket.Suback do
  @moduledoc false

  defstruct [:packet_identifier, :reason_codes, :properties]
end
