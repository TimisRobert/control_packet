defmodule ControlPacket.Unsuback do
  @moduledoc false

  @enforce_keys :packet_identifier
  defstruct packet_identifier: nil, reason_codes: [], properties: []
end
