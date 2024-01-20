defmodule StarflareMqtt.ControlPacket.Connect do
  @moduledoc false

  defstruct [
    :clientid,
    :properties,
    :clean_start,
    :will,
    :username,
    :password,
    :keep_alive,
    :will_retain,
    :will_qos
  ]
end
