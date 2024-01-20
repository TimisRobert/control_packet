defmodule StarflareMqtt.ControlPacket.Pubcomp do
  @moduledoc false

  defstruct [:packet_identifier, :reason_code, :properties]
end
