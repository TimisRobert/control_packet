defmodule StarflareMqtt.Packet.Type.Property do
  @moduledoc false

  alias StarflareMqtt.Packet.Type.{
    Qos,
    Vbi,
    Byte,
    Utf8,
    Binary,
    FourByte,
    TwoByte,
    Utf8Pair
  }

  @payload_format_indicator {0x01, :payload_format_indicator, Byte}
  @message_expiry_interval {0x02, :message_expiry_interval, FourByte}
  @content_type {0x03, :content_type, Utf8}
  @response_topic {0x08, :response_topic, Utf8}
  @correlation_data {0x09, :correlation_data, Binary}
  @subscription_identifier {0x0B, :subscription_identifier, Vbi}
  @session_expiry_interval {0x11, :session_expiry_interval, FourByte}
  @assigned_client_identifier {0x12, :assigned_client_identifier, Utf8}
  @server_keep_alive {0x13, :server_keep_alive, TwoByte}
  @authentication_method {0x15, :authentication_method, Utf8}
  @authentication_data {0x16, :authentication_data, Binary}
  @request_problem_information {0x17, :request_problem_information, Byte}
  @will_delay_interval {0x18, :will_delay_interval, FourByte}
  @request_response_information {0x19, :request_response_information, Byte}
  @response_information {0x1A, :response_information, Utf8}
  @server_reference {0x1C, :server_reference, Utf8}
  @reason_string {0x1F, :reason_string, Utf8}
  @receive_maximum {0x21, :receive_maximum, TwoByte}
  @topic_alias_maximum {0x22, :topic_alias_maximum, TwoByte}
  @topic_alias {0x23, :topic_alias, TwoByte}
  @maximum_qos {0x24, :maximum_qos, Qos}
  @retain_available {0x25, :retain_available, Byte}
  @user_property {0x26, :user_property, Utf8Pair}
  @maximum_packet_size {0x27, :maximum_packet_size, FourByte}
  @wildcard_subscription_available {0x28, :wildcard_subscription_available, Byte}
  @subscription_identifier_available {0x29, :subscription_identifier_available, Byte}
  @shared_subscription_available {0x2A, :shared_subscription_available, Byte}

  @properties [
    @payload_format_indicator,
    @message_expiry_interval,
    @content_type,
    @response_topic,
    @correlation_data,
    @subscription_identifier,
    @session_expiry_interval,
    @assigned_client_identifier,
    @server_keep_alive,
    @authentication_method,
    @authentication_data,
    @request_problem_information,
    @will_delay_interval,
    @request_response_information,
    @response_information,
    @server_reference,
    @reason_string,
    @receive_maximum,
    @topic_alias_maximum,
    @topic_alias,
    @maximum_qos,
    @retain_available,
    @user_property,
    @maximum_packet_size,
    @wildcard_subscription_available,
    @subscription_identifier_available,
    @shared_subscription_available
  ]

  def decode(<<>>), do: {:ok, nil, nil}

  def decode(data) do
    with {:ok, vbi, rest} <- Vbi.decode(data) do
      if vbi > 0 do
        <<properties::binary-size(vbi), rest::binary>> = rest
        {:ok, decode(properties, []), rest}
      else
        {:ok, nil, rest}
      end
    end
  end

  for {code, atom, module} <- @properties do
    defp decode(<<unquote(code), data::binary>>, list) do
      with {:ok, data, rest} <- unquote(module).decode(data) do
        decode(rest, [{unquote(atom), data} | list])
      end
    end
  end

  defp decode(<<_>>, _) do
    {:error, :malformed_packet}
  end

  defp decode(<<>>, list) do
    {user_properties, list} =
      list
      |> Keyword.pop_values(:user_property)

    case user_properties do
      [] -> list
      user_properties -> Keyword.put(list, :user_properties, Enum.into(user_properties, %{}))
    end
    |> Enum.into(%{})
  end

  def encode(nil), do: {:ok, <<0x00>>}

  def encode(properties) do
    with {:ok, encoded_data} <- encode(Map.to_list(properties), <<>>),
         {:ok, vbi} <- Vbi.encode(byte_size(encoded_data)) do
      {:ok, vbi <> encoded_data}
    end
  end

  def encode([], encoded_data), do: {:ok, encoded_data}

  def encode([elem | list], encoded_data) do
    with {:ok, data} <- do_encode(elem) do
      encode(list, data <> encoded_data)
    end
  end

  for {code, atom, module} <- @properties do
    defp do_encode({unquote(atom), value}) do
      with {:ok, data} <- unquote(module).encode(value) do
        {:ok, <<unquote(code)>> <> data}
      end
    end
  end

  defp do_encode({:user_properties, map}) when map_size(map) == 0 do
    {:ok, <<>>}
  end

  defp do_encode({:user_properties, map}) do
    {code, _, _} = @user_property

    with {:ok, data} <- do_encode_user_property(Map.to_list(map), <<>>) do
      {:ok, <<code>> <> data}
    end
  end

  defp do_encode_user_property([], encoded_data), do: {:ok, encoded_data}

  defp do_encode_user_property([value | list], encoded_data) do
    with {:ok, data} <- Utf8Pair.encode(value) do
      do_encode_user_property(list, data <> encoded_data)
    end
  end
end
