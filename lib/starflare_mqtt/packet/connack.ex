defmodule StarflareMqtt.Packet.Connack do
  @moduledoc false
  alias StarflareMqtt.Packet.Type.{Boolean, Property, ReasonCode}

  defstruct [:session_present, :properties, :reason_code]

  def decode(<<_::7, session_present::1, rest::binary>>) do
    with {:ok, session_present} <- Boolean.decode(session_present),
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

  def encode(%__MODULE__{} = connack) do
    %__MODULE__{
      session_present: session_present,
      properties: properties,
      reason_code: reason_code
    } = connack

    with {:ok, data} <- Property.encode(properties),
         encoded_data <- <<data::binary>>,
         {:ok, data} <- ReasonCode.encode(__MODULE__, reason_code),
         encoded_data <- <<data::binary>> <> encoded_data,
         {:ok, data} <- Boolean.encode(session_present),
         encoded_data <- <<0::7, data::1>> <> encoded_data do
      {:ok, encoded_data}
    end
  end
end
