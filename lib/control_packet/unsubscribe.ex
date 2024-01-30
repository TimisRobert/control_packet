defmodule ControlPacket.Unsubscribe do
  @moduledoc false

  @enforce_keys :packet_identifier
  defstruct packet_identifier: nil, topic_filters: [], properties: []
end
