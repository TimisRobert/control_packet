defmodule StarflareMqtt.Packet.Type.Qos do
  @moduledoc false

  def decode(data) do
    case data do
      0 -> {:ok, :at_most_once}
      1 -> {:ok, :al_least_once}
      2 -> {:ok, :exactly_once}
      _ -> {:error, :unsupported_qos}
    end
  end

  def encode(qos) do
    case qos do
      :at_most_once -> {:ok, 0}
      :at_least_once -> {:ok, 1}
      :exactly_once -> {:ok, 2}
      _ -> {:error, :unsupported_qos}
    end
  end
end
