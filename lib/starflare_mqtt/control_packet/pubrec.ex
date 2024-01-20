defmodule StarflareMqtt.ControlPacket.Pubrec do
  @moduledoc false

  defstruct [:packet_identifier, :reason_code, :properties]
end
