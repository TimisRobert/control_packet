defmodule ControlPacket.Pubcomp do
  @moduledoc false

  defstruct packet_identifier: nil, reason_code: :success, properties: []
end
