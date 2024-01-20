defmodule StarflareMqtt.ControlPacket.Connack do
  @moduledoc false

  defstruct [:session_present, :properties, :reason_code]
end
