defmodule StarflareMqtt.Packet.Connack do
  @moduledoc false
  alias StarflareMqtt.Packet.Type.{Boolean, Property, ReasonCode}

  defstruct [:session_present, :properties, :reason_code]

  def decode(<<0::7, rest::bitstring>>) do
    with {:ok, session_present, rest} <- Boolean.decode(rest),
         {:ok, reason_code, rest} <- ReasonCode.decode(__MODULE__, rest),
         {:ok, properties, _} <- Property.decode(rest) do
      {:ok,
       %__MODULE__{
         session_present: session_present,
         properties: properties,
         reason_code: reason_code
       }}
    end
  end

  def decode(<<_::7, _::bitstring>>), do: {:ok, :malformed_packet}

  def encode(%__MODULE__{} = connack) do
    %__MODULE__{
      session_present: session_present,
      properties: properties,
      reason_code: reason_code
    } = connack

    with {:ok, data} <- Property.encode(properties),
         encoded_data <- data,
         {:ok, data} <- ReasonCode.encode(__MODULE__, reason_code),
         encoded_data <- data <> encoded_data,
         {:ok, data} <- Boolean.encode(session_present),
         encoded_data <- <<0::7, data::bitstring>> <> encoded_data do
      {:ok, encoded_data}
    end
  end
end
