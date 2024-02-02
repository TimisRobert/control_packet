defmodule ControlPacket.Pingreq do
  @moduledoc false

  defstruct []

  def new() do
    {:ok, struct!(__MODULE__)}
  end
end
