defmodule StarflareMqtt.Packet.Unsubscribe do
  @moduledoc false

  alias StarflareMqtt.Packet.Type.{Property, Utf8, TwoByte}

  defstruct [:packet_identifier, :topic_filters, :properties]

  def decode(data) do
    with {:ok, packet_identifier, rest} <- TwoByte.decode(data),
         {:ok, properties, rest} <- Property.decode(rest),
         {:ok, topic_filters} <- decode_topic_filters(rest, []) do
      {:ok,
       %__MODULE__{
         packet_identifier: packet_identifier,
         properties: properties,
         topic_filters: topic_filters
       }}
    end
  end

  defp decode_topic_filters(<<>>, list), do: {:ok, list}

  defp decode_topic_filters(data, list) do
    with {:ok, topic_filter, rest} <- Utf8.decode(data) do
      decode_topic_filters(rest, [topic_filter | list])
    end
  end

  def encode(%__MODULE__{} = puback) do
    %__MODULE__{
      packet_identifier: packet_identifier,
      properties: properties,
      topic_filters: topic_filters
    } = puback

    with {:ok, data} <- encode_topic_filters(topic_filters, <<>>),
         encoded_data <- data,
         {:ok, data} <- Property.encode(properties),
         encoded_data <- data <> encoded_data,
         {:ok, data} <- TwoByte.encode(packet_identifier),
         encoded_data <- data <> encoded_data do
      {:ok, encoded_data}
    end
  end

  defp encode_topic_filters([], encoded_data), do: {:ok, encoded_data}

  defp encode_topic_filters([topic_filter | list], encoded_data) do
    with {:ok, data} <- Utf8.encode(topic_filter) do
      encode_topic_filters(list, data <> encoded_data)
    end
  end
end
