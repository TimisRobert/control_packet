defmodule ControlPacket.Disconnect do
  @moduledoc false

  defstruct reason_code: :success, properties: []
end
