defmodule StarflareMqtt.Packet.Subscribe do
  @moduledoc false

  alias StarflareMqtt.Packet.Type.{Property, RetainHandling, Boolean, Qos, Utf8, TwoByte}

  defstruct [:packet_identifier, :topic_filters, :properties]

  def decode(data, <<2::4>>) do
    with {:ok, packet_identifier, rest} <- TwoByte.decode(data),
         {:ok, properties, rest} <- Property.decode(rest),
         {:ok, topic_filters} <- decode_topic_filters(rest, []) do
      {:ok,
       %__MODULE__{
         packet_identifier: packet_identifier,
         topic_filters: topic_filters,
         properties: properties
       }}
    end
  end

  defp decode_topic_filters(<<>>, topic_filters), do: {:ok, Enum.reverse(topic_filters)}

  defp decode_topic_filters(data, topic_filters) do
    with {:ok, topic_filter, rest} <- Utf8.decode(data),
         {:ok, subscription_options, rest} <- decode_subscription_options(rest) do
      decode_topic_filters(rest, [{topic_filter, subscription_options} | topic_filters])
    end
  end

  defp decode_subscription_options(<<0::2, rest::bitstring>>) do
    with {:ok, retain_handling, rest} <- RetainHandling.decode(rest),
         {:ok, rap, rest} <- Boolean.decode(rest),
         {:ok, nl, rest} <- Boolean.decode(rest),
         {:ok, qos, rest} <- Qos.decode(rest) do
      {:ok, [retain_handling: retain_handling, rap: rap, nl: nl, qos: qos], rest}
    end
  end

  defp decode_subscription_options(<<_::2, _::bitstring>>), do: {:error, :malformed_packet}

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
      {:ok, encoded_data, <<2::4>>}
    end
  end

  defp encode_topic_filters([], encoded_data), do: {:ok, encoded_data}

  defp encode_topic_filters([{key, value} | list], encoded_data) do
    with {:ok, data} <- Utf8.encode(key),
         encoded_data <- encoded_data <> data,
         {:ok, data} <- encode_subscription_options(value),
         encoded_data <- encoded_data <> data do
      encode_topic_filters(list, encoded_data)
    end
  end

  defp encode_subscription_options(subscription_options) do
    with {:ok, retain_handling} <- RetainHandling.encode(subscription_options[:retain_handling]),
         {:ok, rap} <- Boolean.encode(subscription_options[:rap]),
         {:ok, nl} <- Boolean.encode(subscription_options[:nl]),
         {:ok, qos} <- Qos.encode(subscription_options[:qos]) do
      {:ok,
       <<
         0::2,
         retain_handling::bitstring,
         rap::bitstring,
         nl::bitstring,
         qos::bitstring
       >>}
    end
  end
end
