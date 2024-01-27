defmodule ControlPacket.Connack do
  @moduledoc false

  defstruct session_present: false, properties: %{}, reason_code: :success
end
