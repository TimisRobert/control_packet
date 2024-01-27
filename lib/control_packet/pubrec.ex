defmodule ControlPacket.Pubrec do
  @moduledoc false

  @enforce_keys :packet_identifier
  defstruct packet_identifier: nil, reason_code: :success, properties: %{}
end
