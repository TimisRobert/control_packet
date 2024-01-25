defmodule ControlPacket.Disconnect do
  @moduledoc false

  defstruct reason_code: :normal_disconnection, properties: []
end
