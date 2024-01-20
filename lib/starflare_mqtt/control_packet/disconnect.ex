defmodule StarflareMqtt.ControlPacket.Disconnect do
  @moduledoc false

  defstruct [:reason_code, :properties]
end
