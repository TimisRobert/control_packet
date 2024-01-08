defmodule StarflareMqtt.Packet.Subscribe do
  @moduledoc false

  alias StarflareMqtt.Packet.Type.{Property, RetainHandling, Boolean, Qos, Utf8, TwoByte}

  defstruct [:packet_identifier, :properties, :topic_filters]

  def decode(data) do
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

  defp decode_topic_filters(<<>>, topic_filters), do: {:ok, Enum.into(topic_filters, %{})}

  defp decode_topic_filters(data, topic_filters) do
    with {:ok, topic_filter, rest} <- Utf8.decode(data),
         {:ok, subscription_options, rest} <- decode_subscription_options(rest) do
      decode_topic_filters(rest, [{topic_filter, subscription_options} | topic_filters])
    end
  end

  defp decode_subscription_options(<<
         _::2,
         retain_handling::2,
         rap::1,
         nl::1,
         qos::2,
         rest::binary
       >>) do
    with {:ok, retain_handling} <- RetainHandling.decode(retain_handling),
         {:ok, rap} <- Boolean.decode(rap),
         {:ok, nl} <- Boolean.decode(nl),
         {:ok, qos} <- Qos.decode(qos) do
      {:ok, %{retain_handling: retain_handling, rap: rap, nl: nl, qos: qos}, rest}
    end
  end

  def encode(%__MODULE__{} = puback) do
    %__MODULE__{
      packet_identifier: packet_identifier,
      properties: properties,
      topic_filters: topic_filters
    } = puback

    with {:ok, data} <- encode_topic_filters(topic_filters),
         encoded_data <- <<data::binary>>,
         {:ok, data} <- Property.encode(properties),
         encoded_data <- <<data::binary>> <> encoded_data,
         {:ok, data} <- TwoByte.encode(packet_identifier),
         encoded_data <- <<data::binary>> <> encoded_data do
      {:ok, encoded_data}
    end
  end

  defp encode_topic_filters(topic_filters) do
    data =
      for {key, value} <- topic_filters, into: <<>> do
        with {:ok, data} <- encode_subscription_options(value),
             encoded_data <- <<data::binary>>,
             {:ok, data} <- Utf8.encode(key) do
          <<data::binary>> <> encoded_data
        end
      end

    {:ok, data}
  end

  defp encode_subscription_options(subscription_options) do
    %{retain_handling: retain_handling, rap: rap, nl: nl, qos: qos} = subscription_options

    with {:ok, retain_handling} <- RetainHandling.encode(retain_handling),
         {:ok, rap} <- Boolean.encode(rap),
         {:ok, nl} <- Boolean.encode(nl),
         {:ok, qos} <- Qos.encode(qos) do
      {:ok,
       <<
         0::2,
         retain_handling::2,
         rap::1,
         nl::1,
         qos::2
       >>}
    end
  end
end
