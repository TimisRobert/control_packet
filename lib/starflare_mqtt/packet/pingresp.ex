defmodule StarflareMqtt.Packet.Pingresp do
  @moduledoc false

  defstruct []

  def decode(<<>>, <<0::4>>) do
    {:ok, %__MODULE__{}}
  end

  def encode(%__MODULE__{}) do
    {:ok, <<>>, <<0::4>>}
  end
end
