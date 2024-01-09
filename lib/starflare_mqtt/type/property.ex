defmodule StarflareMqtt.Type.Property do
  @moduledoc false

  alias StarflareMqtt.Type.{
    Qos,
    Vbi,
    Byte,
    Utf8,
    Binary,
    FourByte,
    TwoByte,
    Utf8Pair
  }

  @payload_format_indicator 0x01
  @message_expiry_interval 0x02
  @content_type 0x03
  @response_topic 0x08
  @correlation_data 0x09
  @subscription_identifier 0x0B
  @session_expiry_interval 0x11
  @assigned_client_identifier 0x12
  @server_keep_alive 0x13
  @authentication_method 0x15
  @authentication_data 0x16
  @request_problem_information 0x17
  @will_delay_interval 0x18
  @request_response_information 0x19
  @response_information 0x1A
  @server_reference 0x1C
  @reason_string 0x1F
  @receive_maximum 0x21
  @topic_alias_maximum 0x22
  @topic_alias 0x23
  @maximum_qos 0x24
  @retain_available 0x25
  @user_property 0x26
  @maximum_packet_size 0x27
  @wildcard_subscription_available 0x28
  @subscription_identifier_available 0x29
  @shared_subscription_available 0x2A

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

  defp decode(<<@payload_format_indicator, data::binary>>, list) do
    with {:ok, data, rest} <- Byte.decode(data) do
      {:ok, decode(rest, [{:payload_format_indicator, data} | list])}
    end
  end

  defp decode(<<@message_expiry_interval, data::binary>>, list) do
    with {:ok, data, rest} <- FourByte.decode(data) do
      decode(rest, [{:message_expiry_interval, data} | list])
    end
  end

  defp decode(<<@content_type, data::binary>>, list) do
    with {:ok, data, rest} <- Utf8.decode(data) do
      decode(rest, [{:content_type, data} | list])
    end
  end

  defp decode(<<@response_topic, data::binary>>, list) do
    with {:ok, data, rest} <- Utf8.decode(data) do
      decode(rest, [{:response_topic, to_string(data)} | list])
    end
  end

  defp decode(<<@correlation_data, data::binary>>, list) do
    with {:ok, data, rest} <- Binary.decode(data) do
      decode(rest, [{:correlation_data, data} | list])
    end
  end

  defp decode(<<@subscription_identifier, data::binary>>, list) do
    with {:ok, vbi, rest} <- Vbi.decode(data) do
      decode(rest, [{:subscription_identifier, vbi} | list])
    end
  end

  defp decode(<<@session_expiry_interval, data::binary>>, list) do
    with {:ok, data, rest} <- FourByte.decode(data) do
      decode(rest, [{:session_expiry_interval, data} | list])
    end
  end

  defp decode(<<@assigned_client_identifier, data::binary>>, list) do
    with {:ok, data, rest} <- Utf8.decode(data) do
      decode(rest, [{:assigned_client_identifier, to_string(data)} | list])
    end
  end

  defp decode(<<@server_keep_alive, data::binary>>, list) do
    with {:ok, data, rest} <- TwoByte.decode(data) do
      decode(rest, [{:server_keep_alive, data} | list])
    end
  end

  defp decode(<<@authentication_method, data::binary>>, list) do
    with {:ok, data, rest} <- Utf8.decode(data) do
      decode(rest, [{:authentication_method, to_string(data)} | list])
    end
  end

  defp decode(<<@authentication_data, data::binary>>, list) do
    with {:ok, data, rest} <- Binary.decode(data) do
      decode(rest, [{:authentication_data, data} | list])
    end
  end

  defp decode(<<@request_problem_information, data::binary>>, list) do
    with {:ok, data, rest} <- Byte.decode(data) do
      decode(rest, [{:request_problem_information, data} | list])
    end
  end

  defp decode(<<@will_delay_interval, data::binary>>, list) do
    with {:ok, data, rest} <- FourByte.decode(data) do
      decode(rest, [{:will_delay_interval, data} | list])
    end
  end

  defp decode(<<@request_response_information, data::binary>>, list) do
    with {:ok, data, rest} <- Byte.decode(data) do
      decode(rest, [{:request_response_information, data} | list])
    end
  end

  defp decode(<<@response_information, data::binary>>, list) do
    with {:ok, data, rest} <- Utf8.decode(data) do
      decode(rest, [{:response_information, to_string(data)} | list])
    end
  end

  defp decode(<<@server_reference, data::binary>>, list) do
    with {:ok, data, rest} <- Utf8.decode(data) do
      decode(rest, [{:server_reference, to_string(data)} | list])
    end
  end

  defp decode(<<@reason_string, data::binary>>, list) do
    with {:ok, data, rest} <- Utf8.decode(data) do
      decode(rest, [{:reason_string, to_string(data)} | list])
    end
  end

  defp decode(<<@receive_maximum, data::binary>>, list) do
    with {:ok, data, rest} <- TwoByte.decode(data) do
      decode(rest, [{:receive_maximum, data} | list])
    end
  end

  defp decode(<<@topic_alias_maximum, data::binary>>, list) do
    with {:ok, data, rest} <- TwoByte.decode(data) do
      decode(rest, [{:topic_alias_maximum, data} | list])
    end
  end

  defp decode(<<@topic_alias, data::binary>>, list) do
    with {:ok, data, rest} <- TwoByte.decode(data) do
      decode(rest, [{:topic_alias, data} | list])
    end
  end

  defp decode(<<@maximum_qos, data::binary>>, list) do
    with {:ok, data, rest} <- Byte.decode(data),
         {:ok, qos} <- Qos.decode(data) do
      decode(rest, [{:maximum_qos, qos} | list])
    end
  end

  defp decode(<<@retain_available, data::binary>>, list) do
    with {:ok, data, rest} <- Byte.decode(data) do
      decode(rest, [{:retain_available, data} | list])
    end
  end

  defp decode(<<@user_property, data::binary>>, list) do
    with {:ok, data, rest} <- Utf8Pair.decode(data) do
      decode(rest, [{:user_property, data} | list])
    end
  end

  defp decode(<<@maximum_packet_size, data::binary>>, list) do
    with {:ok, data, rest} <- FourByte.decode(data) do
      decode(rest, [{:maximum_packet_size, data} | list])
    end
  end

  defp decode(<<@wildcard_subscription_available, data::binary>>, list) do
    with {:ok, data, rest} <- Byte.decode(data) do
      decode(rest, [{:wildcard_subscription_available, data} | list])
    end
  end

  defp decode(<<@subscription_identifier_available, data::binary>>, list) do
    with {:ok, data, rest} <- Byte.decode(data) do
      decode(rest, [{:subscription_identifier_available, data} | list])
    end
  end

  defp decode(<<@shared_subscription_available, data::binary>>, list) do
    with {:ok, data, rest} <- Byte.decode(data) do
      decode(rest, [{:shared_subscription_available, data} | list])
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

  def encode(map) do
    data =
      for value <- map, into: <<>> do
        {:ok, data} = do_encode(value)
        data
      end

    with {:ok, vbi} <- Vbi.encode(byte_size(data)) do
      {:ok, vbi <> data}
    end
  end

  defp do_encode({:payload_format_indicator, value}) do
    with {:ok, data} <- Byte.encode(value) do
      {:ok, <<@payload_format_indicator>> <> data}
    end
  end

  defp do_encode({:message_expiry_interval, value}) do
    with {:ok, data} <- FourByte.encode(value) do
      {:ok, <<@message_expiry_interval>> <> data}
    end
  end

  defp do_encode({:content_type, value}) do
    with {:ok, data} <- Utf8.encode(value) do
      {:ok, <<@content_type>> <> data}
    end
  end

  defp do_encode({:response_topic, value}) do
    with {:ok, data} <- Utf8.encode(value) do
      {:ok, <<@response_topic>> <> data}
    end
  end

  defp do_encode({:correlation_data, value}) do
    with {:ok, data} <- Binary.encode(value) do
      {:ok, <<@correlation_data>> <> data}
    end
  end

  defp do_encode({:subscription_identifier, value}) do
    with {:ok, data} <- Vbi.encode(value) do
      {:ok, <<@subscription_identifier>> <> data}
    end
  end

  defp do_encode({:session_expiry_interval, value}) do
    with {:ok, data} <- FourByte.encode(value) do
      {:ok, <<@session_expiry_interval>> <> data}
    end
  end

  defp do_encode({:assigned_client_identifier, value}) do
    with {:ok, data} <- Utf8.encode(value) do
      {:ok, <<@assigned_client_identifier>> <> data}
    end
  end

  defp do_encode({:server_keep_alive, value}) do
    with {:ok, data} <- TwoByte.encode(value) do
      {:ok, <<@server_keep_alive>> <> data}
    end
  end

  defp do_encode({:authentication_method, value}) do
    with {:ok, data} <- Utf8.encode(value) do
      {:ok, <<@authentication_method>> <> data}
    end
  end

  defp do_encode({:authentication_data, value}) do
    with {:ok, data} <- Binary.encode(value) do
      {:ok, <<@authentication_data>> <> data}
    end
  end

  defp do_encode({:request_problem_information, value}) do
    with {:ok, data} <- Byte.encode(value) do
      {:ok, <<@request_problem_information>> <> data}
    end
  end

  defp do_encode({:will_delay_interval, value}) do
    with {:ok, data} <- FourByte.encode(value) do
      {:ok, <<@will_delay_interval>> <> data}
    end
  end

  defp do_encode({:request_response_information, value}) do
    with {:ok, data} <- Byte.encode(value) do
      {:ok, <<@request_response_information>> <> data}
    end
  end

  defp do_encode({:response_information, value}) do
    with {:ok, data} <- Utf8.encode(value) do
      {:ok, <<@response_information>> <> data}
    end
  end

  defp do_encode({:server_reference, value}) do
    with {:ok, data} <- Utf8.encode(value) do
      {:ok, <<@server_reference>> <> data}
    end
  end

  defp do_encode({:reason_string, value}) do
    with {:ok, data} <- Utf8.encode(value) do
      {:ok, <<@reason_string>> <> data}
    end
  end

  defp do_encode({:receive_maximum, value}) do
    with {:ok, data} <- TwoByte.encode(value) do
      {:ok, <<@receive_maximum>> <> data}
    end
  end

  defp do_encode({:topic_alias_maximum, value}) do
    with {:ok, data} <- TwoByte.encode(value) do
      {:ok, <<@topic_alias_maximum>> <> data}
    end
  end

  defp do_encode({:topic_alias, value}) do
    with {:ok, data} <- TwoByte.encode(value) do
      {:ok, <<@topic_alias>> <> data}
    end
  end

  defp do_encode({:maximum_qos, value}) do
    with {:ok, value} <- Qos.encode(value),
         {:ok, data} <- Byte.encode(value) do
      {:ok, <<@maximum_qos>> <> data}
    end
  end

  defp do_encode({:retain_available, value}) do
    with {:ok, data} <- Byte.encode(value) do
      {:ok, <<@retain_available>> <> data}
    end
  end

  defp do_encode({:user_properties, map}) when map_size(map) == 0 do
    {:ok, <<>>}
  end

  defp do_encode({:user_properties, map}) do
    data =
      for value <- map, into: <<>> do
        {:ok, data} = Utf8Pair.encode(value)
        data
      end

    {:ok, <<@user_property>> <> data}
  end

  defp do_encode({:maximum_packet_size, value}) do
    with {:ok, data} <- FourByte.encode(value) do
      {:ok, <<@maximum_packet_size>> <> data}
    end
  end

  defp do_encode({:wildcard_subscription_available, value}) do
    with {:ok, data} <- Byte.encode(value) do
      {:ok, <<@wildcard_subscription_available>> <> data}
    end
  end

  defp do_encode({:subscription_identifier_available, value}) do
    with {:ok, data} <- Byte.encode(value) do
      {:ok, <<@subscription_identifier_available>> <> data}
    end
  end

  defp do_encode({:shared_subscription_available, value}) do
    with {:ok, data} <- Byte.encode(value) do
      {:ok, <<@shared_subscription_available>> <> data}
    end
  end
end
