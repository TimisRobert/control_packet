defmodule StarflareMqtt.Type.Boolean do
  @moduledoc false

  def decode(integer), do: {:ok, integer == 1}

  def encode(true), do: {:ok, 1}
  def encode(false), do: {:ok, 0}
end
