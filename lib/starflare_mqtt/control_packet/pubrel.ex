defmodule StarflareMqtt.ControlPacket.Pubrel do
  @moduledoc false

  defstruct [:packet_identifier, :reason_code, :properties]
end
