defmodule ControlPacket.Connack do
  @moduledoc false

  defstruct session_present: false, reason_code: :success, properties: []
end
