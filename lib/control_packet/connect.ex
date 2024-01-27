defmodule ControlPacket.Connect do
  @moduledoc false

  defstruct clientid: "",
            properties: %{},
            clean_start: true,
            will: nil,
            will_retain: false,
            will_qos: :at_most_once,
            username: "",
            password: "",
            keep_alive: 60
end
