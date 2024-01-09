defmodule StarflareMqtt.Unsuback do
  @moduledoc false

  alias StarflareMqtt.Type.{Property, ReasonCode, TwoByte}

  defstruct [:packet_identifier, :reason_codes, :properties]

  def decode(data) do
    with {:ok, packet_identifier, rest} <- TwoByte.decode(data),
         {:ok, properties, rest} <- Property.decode(rest),
         {:ok, reason_codes} <- decode_reason_codes(rest, []) do
      {:ok,
       %__MODULE__{
         packet_identifier: packet_identifier,
         properties: properties,
         reason_codes: reason_codes
       }}
    end
  end

  defp decode_reason_codes(<<>>, list), do: {:ok, list}

  defp decode_reason_codes(data, list) do
    with {:ok, code, rest} <- ReasonCode.decode(__MODULE__, data) do
      decode_reason_codes(rest, [code | list])
    end
  end

  defp encode_reason_codes([], encoded_data), do: {:ok, encoded_data}

  defp encode_reason_codes([code | list], encoded_data) do
    with {:ok, data} <- ReasonCode.encode(__MODULE__, code) do
      encode_reason_codes(list, data <> encoded_data)
    end
  end

  def encode(%__MODULE__{} = puback) do
    %__MODULE__{
      packet_identifier: packet_identifier,
      reason_codes: reason_codes,
      properties: properties
    } = puback

    with {:ok, data} <- encode_reason_codes(reason_codes, <<>>),
         encoded_data <- data,
         {:ok, data} <- Property.encode(properties),
         encoded_data <- data <> encoded_data,
         {:ok, data} <- TwoByte.encode(packet_identifier),
         encoded_data <- data <> encoded_data do
      {:ok, encoded_data}
    end
  end
end
