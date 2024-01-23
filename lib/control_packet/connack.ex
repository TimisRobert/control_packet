defmodule ControlPacket.Connack do
  @moduledoc false

  defstruct session_present: nil, properties: [], reason_code: :success
end
