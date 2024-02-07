defmodule ControlPacket.Suback do
  @moduledoc false

  defstruct packet_identifier: nil, reason_codes: [], properties: []
end
