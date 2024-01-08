defmodule StarflareMqtt.Packet.Pingreq do
  @moduledoc false

  defstruct []

  def decode(<<>>) do
    {:ok, %__MODULE__{}}
  end

  def encode(%__MODULE__{}) do
    {:ok, <<>>}
  end
end
