defmodule StarflareMqtt.Type.Qos do
  @moduledoc false

  @at_most_once 0
  @at_least_once 1
  @exactly_once 2

  def decode(data) do
    case data do
      @at_most_once -> {:ok, :at_most_once}
      @at_least_once -> {:ok, :at_least_once}
      @exactly_once -> {:ok, :exactly_once}
      _ -> {:error, :qos_not_supported}
    end
  end

  def encode(qos) do
    case qos do
      :at_most_once -> {:ok, @at_most_once}
      :at_least_once -> {:ok, @at_least_once}
      :exactly_once -> {:ok, @exactly_once}
      _ -> {:error, :qos_not_supported}
    end
  end
end
