defmodule ControlPacket.Unsuback do
  @moduledoc false

  defstruct packet_identifier: nil, reason_codes: [], properties: []
end
