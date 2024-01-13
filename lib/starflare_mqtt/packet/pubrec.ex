defmodule StarflareMqtt.Packet.Pubrec do
  @moduledoc false

  alias StarflareMqtt.Packet.Type.{Property, ReasonCode, TwoByte}

  defstruct [:packet_identifier, :reason_code, :properties]

  def decode(data, <<0::4>>) when byte_size(data) == 2 do
    with {:ok, packet_identifier, _} <- TwoByte.decode(data) do
      {:ok, %__MODULE__{packet_identifier: packet_identifier, reason_code: :success}}
    end
  end

  def decode(data, <<0::4>>) do
    with {:ok, packet_identifier, rest} <- TwoByte.decode(data),
         {:ok, reason_code, rest} <- ReasonCode.decode(__MODULE__, rest),
         {:ok, properties, _} <- Property.decode(rest) do
      {:ok,
       %__MODULE__{
         packet_identifier: packet_identifier,
         properties: properties,
         reason_code: reason_code
       }}
    end
  end

  def encode(%__MODULE__{reason_code: nil} = puback) do
    %__MODULE__{
      packet_identifier: packet_identifier
    } = puback

    with {:ok, data} <- TwoByte.encode(packet_identifier) do
      {:ok, data, <<0::4>>}
    end
  end

  def encode(%__MODULE__{} = puback) do
    %__MODULE__{
      packet_identifier: packet_identifier,
      reason_code: reason_code,
      properties: properties
    } = puback

    with {:ok, data} <- Property.encode(properties),
         encoded_data <- data,
         {:ok, data} <- ReasonCode.encode(__MODULE__, reason_code),
         encoded_data <- data <> encoded_data,
         {:ok, data} <- TwoByte.encode(packet_identifier),
         encoded_data <- data <> encoded_data do
      {:ok, encoded_data, <<0::4>>}
    end
  end
end
