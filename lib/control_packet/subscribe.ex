defmodule ControlPacket.Subscribe do
  @moduledoc false

  defstruct packet_identifier: nil, topic_filters: [], properties: []
end
