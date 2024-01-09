defmodule StarflareMqtt.Publish do
  @moduledoc false

  alias StarflareMqtt.Type.{
    TwoByte,
    Property,
    Utf8,
    Qos,
    Boolean
  }

  defstruct [
    :dup_flag,
    :qos_level,
    :retain,
    :topic_name,
    :packet_identifier,
    :properties,
    :payload
  ]

  def decode(data, flags) do
    with {:ok, {dup_flag, qos_level, retain}} <- decode_flags(flags),
         {:ok, topic_name, rest} <- Utf8.decode(data),
         {:ok, packet_identifier, rest} <- decode_packet_identifier(qos_level, rest),
         {:ok, properties, payload} <- Property.decode(rest) do
      {:ok,
       %__MODULE__{
         dup_flag: dup_flag,
         qos_level: qos_level,
         retain: retain,
         topic_name: topic_name,
         packet_identifier: packet_identifier,
         properties: properties,
         payload: payload
       }}
    end
  end

  defp decode_packet_identifier(:at_most_once, data), do: {:ok, nil, data}
  defp decode_packet_identifier(_, data), do: TwoByte.decode(data)

  defp decode_flags(<<dup_flag::1, qos_level::2, retain::1>>) do
    with {:ok, dup_flag} <- Boolean.decode(dup_flag),
         {:ok, qos_level} <- Qos.decode(qos_level),
         {:ok, retain} <- Boolean.decode(retain) do
      {:ok, {dup_flag, qos_level, retain}}
    end
  end

  def encode(%__MODULE__{} = publish) do
    %__MODULE__{
      dup_flag: dup_flag,
      qos_level: qos_level,
      retain: retain,
      topic_name: topic_name,
      packet_identifier: packet_identifier,
      properties: properties,
      payload: payload
    } = publish

    with {:ok, data} <- Property.encode(properties),
         encoded_data <- data <> payload,
         {:ok, data} <- encode_packet_identifier(qos_level, packet_identifier),
         encoded_data <- data <> encoded_data,
         {:ok, data} <- Utf8.encode(topic_name),
         encoded_data <- data <> encoded_data,
         {:ok, flags} <- encode_flags(dup_flag, qos_level, retain) do
      {:ok, encoded_data, flags}
    end
  end

  defp encode_flags(dup_flag, qos_level, retain) do
    with {:ok, dup_flag} <- Boolean.encode(dup_flag),
         {:ok, qos_level} <- Qos.encode(qos_level),
         {:ok, retain} <- Boolean.encode(retain) do
      {:ok, <<dup_flag::1, qos_level::2, retain::1>>}
    end
  end

  defp encode_packet_identifier(:at_most_once, _), do: {:ok, <<>>}
  defp encode_packet_identifier(_, data), do: TwoByte.encode(data)
end
