defmodule ControlPacket do
  @moduledoc false

  import Bitwise

  @connect 0x1
  @connack 0x2
  @publish 0x3
  @puback 0x4
  @pubrec 0x5
  @pubrel 0x6
  @pubcomp 0x7
  @subscribe 0x8
  @suback 0x9
  @unsubscribe 0xA
  @unsuback 0xB
  @pingreq 0xC
  @pingresp 0xD
  @disconnect 0xE
  @auth 0xF

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

  @success 0x00
  @normal_disconnection 0x00
  @granted_qos_0 0x00
  @granted_qos_1 0x01
  @granted_qos_2 0x02
  @disconnect_with_will_message 0x04
  @no_matching_subscribers 0x10
  @no_subscription_existed 0x11
  @continue_authentication 0x18
  @re_authenticate 0x19
  @unspecified_error 0x80
  @malformed_packet 0x81
  @protocol_error 0x82
  @implementation_specific_error 0x83
  @unsupported_protocol_error 0x84
  @client_identifier_not_valid 0x85
  @bad_username_or_password 0x86
  @not_authorized 0x87
  @server_unavailable 0x88
  @server_busy 0x89
  @banned 0x8A
  @server_shutting_down 0x8B
  @bad_authentication_method 0x8C
  @keep_alive_timeout 0x8D
  @session_taken_over 0x8E
  @topic_filter_invalid 0x8F
  @topic_name_invalid 0x90
  @packet_identifier_in_use 0x91
  @packet_identifier_not_found 0x92
  @receive_maximum_exceeded 0x93
  @topic_alias_invalid 0x94
  @packet_too_large 0x95
  @message_rate_too_high 0x96
  @quota_exceeded 0x97
  @administrative_action 0x98
  @payload_format_invalid 0x99
  @retain_not_supported 0x9A
  @qos_not_supported 0x9B
  @use_another_server 0x9C
  @server_moved 0x9D
  @shared_subscriptions_not_supported 0x9E
  @connection_rate_exceeded 0x9F
  @maximum_connect_time 0xA0
  @subscription_identifiers_not_supported 0xA1
  @wildcard_subscriptions_not_supported 0xA2

  @at_most_once 0b00
  @at_least_once 0b01
  @exactly_once 0b10

  @send_when_subscribed 0b00
  @send_if_no_subscription 0b01
  @dont_send 0b10

  def decode_buffer(buffer) do
    IO.iodata_to_binary(buffer)
    |> decode_buffer([])
  end

  defp decode_buffer(<<>>, list) do
    {:ok, Enum.reverse(list)}
  end

  defp decode_buffer(<<buffer::bytes>>, list) do
    case decode(buffer) do
      {:ok, packet, size} ->
        <<_::bytes-size(size), buffer::bytes>> = buffer
        decode_buffer(buffer, [packet | list])

      {:error, error} ->
        {:error, error, Enum.reverse(list)}
    end
  end

  defp decode(<<@connect::4, 0::4, rest::bytes>>) do
    with {:ok, packet_vbi, packet_vbi_size} <- decode_vbi(rest),
         <<_::bytes-size(packet_vbi_size), rest::bytes-size(packet_vbi), _::bytes>> <- rest do
      with <<4::16, "MQTT", 5, username_flag::1, password_flag::1, will_retain::1, will_qos::2,
             will_flag::1, clean_start::1, 0::1, keep_alive::16, rest::bytes>> <- rest,
           {:ok, vbi, size} <- decode_vbi(rest),
           <<_::bytes-size(size), properties::bytes-size(vbi), rest::bytes>> <- rest,
           <<size::16, clientid::bytes-size(size), rest::bytes>> <- rest do
        with {:ok, will_qos} <- decode_qos(will_qos),
             {:ok, properties} <- decode_properties(@connect, properties),
             {:ok, will, size} <- decode_will(will_flag == 1, rest),
             {:ok, username, size} <- decode_string(username_flag == 1, size, rest),
             {:ok, password, _} <- decode_string(password_flag == 1, size, rest) do
          {:ok,
           %ControlPacket.Connect{
             clientid: clientid,
             will: will,
             will_retain: will_retain == 1,
             clean_start: clean_start == 1,
             will_qos: will_qos,
             keep_alive: keep_alive,
             properties: properties,
             username: username,
             password: password
           }, packet_vbi + packet_vbi_size + 1}
        end
      else
        _ -> {:error, :malformed_packet}
      end
    else
      _ -> {:error, :incomplete_packet}
    end
  end

  defp decode(<<@connack::4, 0::4, rest::bytes>>) do
    with {:ok, packet_vbi, packet_vbi_size} <- decode_vbi(rest),
         <<_::bytes-size(packet_vbi_size), rest::bytes-size(packet_vbi), _::bytes>> <- rest do
      with <<0::7, session_present::1, reason_code, rest::bytes>> <- rest,
           {:ok, vbi, size} <- decode_vbi(rest),
           <<_::bytes-size(size), properties::bytes-size(vbi)>> <- rest do
        with {:ok, reason_code} <- decode_reason_code(@connack, reason_code),
             {:ok, properties} <- decode_properties(@connack, properties) do
          {:ok,
           %ControlPacket.Connack{
             session_present: session_present == 1,
             reason_code: reason_code,
             properties: properties
           }, packet_vbi + packet_vbi_size + 1}
        end
      else
        _ -> {:error, :malformed_packet}
      end
    else
      _ -> {:error, :incomplete_packet}
    end
  end

  defp decode(<<@publish::4, flags::bits-4, rest::bytes>>) do
    with {:ok, packet_vbi, packet_vbi_size} <- decode_vbi(rest),
         <<_::bytes-size(packet_vbi_size), rest::bytes-size(packet_vbi), _::bytes>> <- rest do
      with <<dup_flag::1, qos_level::2, retain::1>> <- flags,
           {:ok, qos_level} <- decode_qos(qos_level),
           <<length::16, topic_name::bytes-size(length), rest::bytes>> <- rest,
           {:ok, packet_identifier, size} <- decode_packet_identifier(qos_level, rest),
           <<_::size(size), rest::bytes>> <- rest,
           {:ok, vbi, size} <- decode_vbi(rest),
           <<_::bytes-size(size), properties::bytes-size(vbi), payload_size::16,
             payload::bytes-size(payload_size)>> <- rest do
        with {:ok, properties} <- decode_properties(@publish, properties) do
          {:ok,
           %ControlPacket.Publish{
             dup_flag: dup_flag == 1,
             qos_level: qos_level,
             retain: retain == 1,
             topic_name: topic_name,
             packet_identifier: packet_identifier,
             properties: properties,
             payload: payload
           }, packet_vbi + packet_vbi_size + 1}
        end
      else
        _ -> {:error, :malformed_packet}
      end
    else
      _ -> {:error, :incomplete_packet}
    end
  end

  defp decode(<<@puback::4, 0::4, 2, packet_identifier::16, _::bytes>>) do
    {:ok,
     %ControlPacket.Puback{
       packet_identifier: packet_identifier,
       reason_code: :success
     }, 4}
  end

  defp decode(<<@puback::4, 0::4, 3, packet_identifier::16, reason_code, _::bytes>>) do
    with {:ok, reason_code} <- decode_reason_code(@puback, reason_code) do
      {:ok,
       %ControlPacket.Puback{
         packet_identifier: packet_identifier,
         reason_code: reason_code
       }, 5}
    end
  end

  defp decode(<<@puback::4, 0::4, rest::bytes>>) do
    with {:ok, packet_vbi, packet_vbi_size} <- decode_vbi(rest),
         <<_::bytes-size(packet_vbi_size), rest::bytes-size(packet_vbi), _::bytes>> <- rest do
      with <<packet_identifier::16, reason_code, rest::bytes>> <- rest,
           {:ok, vbi, size} <- decode_vbi(rest),
           <<_::bytes-size(size), properties::bytes-size(vbi)>> <- rest do
        with {:ok, reason_code} <- decode_reason_code(@puback, reason_code),
             {:ok, properties} <- decode_properties(@puback, properties) do
          {:ok,
           %ControlPacket.Puback{
             packet_identifier: packet_identifier,
             reason_code: reason_code,
             properties: properties
           }, packet_vbi + packet_vbi_size + 1}
        end
      else
        _ -> {:error, :malformed_packet}
      end
    else
      _ -> {:error, :incomplete_packet}
    end
  end

  defp decode(<<@pubrec::4, 0::4, 2, packet_identifier::16, _::bytes>>) do
    {:ok,
     %ControlPacket.Pubrec{
       packet_identifier: packet_identifier,
       reason_code: :success
     }, 4}
  end

  defp decode(<<@pubrec::4, 0::4, 3, packet_identifier::16, reason_code, _::bytes>>) do
    with {:ok, reason_code} <- decode_reason_code(@pubrec, reason_code) do
      {:ok,
       %ControlPacket.Pubrec{
         packet_identifier: packet_identifier,
         reason_code: reason_code
       }, 5}
    end
  end

  defp decode(<<@pubrec::4, 0::4, rest::bytes>>) do
    with {:ok, packet_vbi, packet_vbi_size} <- decode_vbi(rest),
         <<_::bytes-size(packet_vbi_size), rest::bytes-size(packet_vbi), _::bytes>> <- rest do
      with <<packet_identifier::16, reason_code, rest::bytes>> <- rest,
           {:ok, vbi, size} <- decode_vbi(rest),
           <<_::bytes-size(size), properties::bytes-size(vbi)>> <- rest do
        with {:ok, reason_code} <- decode_reason_code(@pubrec, reason_code),
             {:ok, properties} <- decode_properties(@pubrec, properties) do
          {:ok,
           %ControlPacket.Pubrec{
             packet_identifier: packet_identifier,
             reason_code: reason_code,
             properties: properties
           }, packet_vbi + packet_vbi_size + 1}
        end
      else
        _ -> {:error, :malformed_packet}
      end
    else
      _ -> {:error, :incomplete_packet}
    end
  end

  defp decode(<<@pubrel::4, 2::4, 2, packet_identifier::16, _::bytes>>) do
    {:ok,
     %ControlPacket.Pubrel{
       packet_identifier: packet_identifier,
       reason_code: :success
     }, 4}
  end

  defp decode(<<@pubrel::4, 2::4, 3, packet_identifier::16, reason_code, _::bytes>>) do
    with {:ok, reason_code} <- decode_reason_code(@pubrel, reason_code) do
      {:ok,
       %ControlPacket.Pubrel{
         packet_identifier: packet_identifier,
         reason_code: reason_code
       }, 5}
    end
  end

  defp decode(<<@pubrel::4, 2::4, rest::bytes>>) do
    with {:ok, packet_vbi, packet_vbi_size} <- decode_vbi(rest),
         <<_::bytes-size(packet_vbi_size), rest::bytes-size(packet_vbi), _::bytes>> <- rest do
      with <<packet_identifier::16, reason_code, rest::bytes>> <- rest,
           {:ok, vbi, size} <- decode_vbi(rest),
           <<_::bytes-size(size), properties::bytes-size(vbi)>> <- rest do
        with {:ok, reason_code} <- decode_reason_code(@pubrel, reason_code),
             {:ok, properties} <- decode_properties(@pubrel, properties) do
          {:ok,
           %ControlPacket.Pubrel{
             packet_identifier: packet_identifier,
             reason_code: reason_code,
             properties: properties
           }, packet_vbi + packet_vbi_size + 1}
        end
      else
        _ -> {:error, :malformed_packet}
      end
    else
      _ -> {:error, :incomplete_packet}
    end
  end

  defp decode(<<@pubcomp::4, 0::4, 2, packet_identifier::16, _::bytes>>) do
    {:ok,
     %ControlPacket.Pubcomp{
       packet_identifier: packet_identifier,
       reason_code: :success
     }, 4}
  end

  defp decode(<<@pubcomp::4, 0::4, 3, packet_identifier::16, reason_code, _::bytes>>) do
    with {:ok, reason_code} <- decode_reason_code(@pubcomp, reason_code) do
      {:ok,
       %ControlPacket.Pubcomp{
         packet_identifier: packet_identifier,
         reason_code: reason_code
       }, 5}
    end
  end

  defp decode(<<@pubcomp::4, 0::4, rest::bytes>>) do
    with {:ok, packet_vbi, packet_vbi_size} <- decode_vbi(rest),
         <<_::bytes-size(packet_vbi_size), rest::bytes-size(packet_vbi), _::bytes>> <- rest do
      with <<packet_identifier::16, reason_code, rest::bytes>> <- rest,
           {:ok, vbi, size} <- decode_vbi(rest),
           <<_::bytes-size(size), properties::bytes-size(vbi)>> <- rest do
        with {:ok, reason_code} <- decode_reason_code(@pubcomp, reason_code),
             {:ok, properties} <- decode_properties(@pubcomp, properties) do
          {:ok,
           %ControlPacket.Pubcomp{
             packet_identifier: packet_identifier,
             reason_code: reason_code,
             properties: properties
           }, packet_vbi + packet_vbi_size + 1}
        end
      else
        _ -> {:error, :malformed_packet}
      end
    else
      _ -> {:error, :incomplete_packet}
    end
  end

  defp decode(<<@subscribe::4, 2::4, rest::bytes>>) do
    with {:ok, packet_vbi, packet_vbi_size} <- decode_vbi(rest),
         <<_::bytes-size(packet_vbi_size), rest::bytes-size(packet_vbi), _::bytes>> <- rest do
      with <<packet_identifier::16, rest::bytes>> <- rest,
           {:ok, vbi, size} <- decode_vbi(rest),
           <<_::bytes-size(size), properties::bytes-size(vbi), rest::bytes>> <- rest do
        with {:ok, properties} <- decode_properties(@subscribe, properties),
             {:ok, topic_filters} <- decode_topic_flag_filters(rest) do
          {:ok,
           %ControlPacket.Subscribe{
             packet_identifier: packet_identifier,
             properties: properties,
             topic_filters: topic_filters
           }, packet_vbi + packet_vbi_size + 1}
        end
      else
        _ -> {:error, :malformed_packet}
      end
    else
      _ -> {:error, :incomplete_packet}
    end
  end

  defp decode(<<@suback::4, 0::4, rest::bytes>>) do
    with {:ok, packet_vbi, packet_vbi_size} <- decode_vbi(rest),
         <<_::bytes-size(packet_vbi_size), rest::bytes-size(packet_vbi), _::bytes>> <- rest do
      with <<packet_identifier::16, rest::bytes>> <- rest,
           {:ok, vbi, size} <- decode_vbi(rest),
           <<_::bytes-size(size), properties::bytes-size(vbi), rest::bytes>> <- rest do
        with {:ok, properties} <- decode_properties(@suback, properties),
             {:ok, reason_codes} <- decode_reason_codes(@suback, rest) do
          {:ok,
           %ControlPacket.Suback{
             packet_identifier: packet_identifier,
             properties: properties,
             reason_codes: reason_codes
           }, packet_vbi + packet_vbi_size + 1}
        end
      else
        _ -> {:error, :malformed_packet}
      end
    else
      _ -> {:error, :incomplete_packet}
    end
  end

  defp decode(<<@unsubscribe::4, 2::4, rest::bytes>>) do
    with {:ok, packet_vbi, packet_vbi_size} <- decode_vbi(rest),
         <<_::bytes-size(packet_vbi_size), rest::bytes-size(packet_vbi), _::bytes>> <- rest do
      with <<packet_identifier::16, rest::bytes>> <- rest,
           {:ok, vbi, size} <- decode_vbi(rest),
           <<_::bytes-size(size), properties::bytes-size(vbi), rest::bytes>> <- rest do
        with {:ok, properties} <- decode_properties(@unsubscribe, properties),
             {:ok, topic_filters} <- decode_topic_filters(rest) do
          {:ok,
           %ControlPacket.Unsubscribe{
             packet_identifier: packet_identifier,
             properties: properties,
             topic_filters: topic_filters
           }, packet_vbi + packet_vbi_size + 1}
        end
      else
        _ -> {:error, :malformed_packet}
      end
    else
      _ -> {:error, :incomplete_packet}
    end
  end

  defp decode(<<@unsuback::4, 0::4, rest::bytes>>) do
    with {:ok, packet_vbi, packet_vbi_size} <- decode_vbi(rest),
         <<_::bytes-size(packet_vbi_size), rest::bytes-size(packet_vbi), _::bytes>> <- rest do
      with <<packet_identifier::16, rest::bytes>> <- rest,
           {:ok, vbi, size} <- decode_vbi(rest),
           <<_::bytes-size(size), properties::bytes-size(vbi), rest::bytes>> <- rest do
        with {:ok, properties} <- decode_properties(@unsuback, properties),
             {:ok, reason_codes} <- decode_reason_codes(@unsuback, rest) do
          {:ok,
           %ControlPacket.Unsuback{
             packet_identifier: packet_identifier,
             properties: properties,
             reason_codes: reason_codes
           }, packet_vbi + packet_vbi_size + 1}
        end
      else
        _ -> {:error, :malformed_packet}
      end
    else
      _ -> {:error, :incomplete_packet}
    end
  end

  defp decode(<<@pingreq::4, 0::4, 0, _::bytes>>) do
    {:ok, %ControlPacket.Pingreq{}, 2}
  end

  defp decode(<<@pingresp::4, 0::4, 0, _::bytes>>) do
    {:ok, %ControlPacket.Pingresp{}, 2}
  end

  defp decode(<<@disconnect::4, 0::4, 0, _::bytes>>) do
    {:ok, %ControlPacket.Disconnect{reason_code: :normal_disconnection}, 2}
  end

  defp decode(<<@disconnect::4, 0::4, 1, reason_code, _::bytes>>) do
    with {:ok, reason_code} <- decode_reason_code(@disconnect, reason_code) do
      {:ok, %ControlPacket.Disconnect{reason_code: reason_code}, 3}
    end
  end

  defp decode(<<@disconnect::4, 0::4, rest::bytes>>) do
    with {:ok, packet_vbi, packet_vbi_size} <- decode_vbi(rest),
         <<_::bytes-size(packet_vbi_size), rest::bytes-size(packet_vbi), _::bytes>> <- rest do
      with <<reason_code, rest::bytes>> <- rest,
           {:ok, vbi, size} <- decode_vbi(rest),
           <<_::bytes-size(size), properties::bytes-size(vbi)>> <- rest do
        with {:ok, reason_code} <- decode_reason_code(@disconnect, reason_code),
             {:ok, properties} <- decode_properties(@disconnect, properties) do
          {:ok,
           %ControlPacket.Disconnect{
             reason_code: reason_code,
             properties: properties
           }, packet_vbi + packet_vbi_size + 1}
        end
      else
        _ -> {:error, :malformed_packet}
      end
    else
      _ -> {:error, :incomplete_packet}
    end
  end

  defp decode(<<@auth::4, 0::4, 0, _::bytes>>) do
    {:ok, %ControlPacket.Auth{reason_code: :success}, 2}
  end

  defp decode(<<@auth::4, 0::4, rest::bytes>>) do
    with {:ok, packet_vbi, packet_vbi_size} <- decode_vbi(rest),
         <<_::bytes-size(packet_vbi_size), rest::bytes-size(packet_vbi), _::bytes>> <- rest do
      with <<reason_code, rest::bytes>> <- rest,
           {:ok, vbi, size} <- decode_vbi(rest),
           <<_::bytes-size(size), properties::bytes-size(vbi)>> <- rest do
        with {:ok, reason_code} <- decode_reason_code(@auth, reason_code),
             {:ok, properties} <- decode_properties(@auth, properties) do
          {:ok,
           %ControlPacket.Auth{
             reason_code: reason_code,
             properties: properties
           }, packet_vbi + packet_vbi_size + 1}
        end
      else
        _ -> {:error, :malformed_packet}
      end
    else
      _ -> {:error, :incomplete_packet}
    end
  end

  defp decode(_), do: {:error, :malformed_packet}

  defp decode_packet_identifier(:at_most_once, <<_::bytes>>), do: {:ok, nil, 0}

  defp decode_packet_identifier(_, <<rest::bytes>>) do
    case rest do
      <<packet_identifier::16, _::bytes>> -> {:ok, packet_identifier, 16}
      _ -> {:error, :malformed_packet}
    end
  end

  defp decode_string(false, _, <<_::bytes>>), do: {:ok, nil, 0}

  defp decode_string(true, size, <<rest::bytes>>) do
    case rest do
      <<_::bytes-size(size), size::16, string::bytes-size(size), _::bytes>> ->
        {:ok, string, size + 2}

      _ ->
        {:error, :malformed_packet}
    end
  end

  defp decode_will(false, <<_::bytes>>), do: {:ok, nil, 0}

  defp decode_will(true, <<rest::bytes>>) do
    with {:ok, vbi, size} <- decode_vbi(rest),
         <<_::bytes-size(size), properties::bytes-size(vbi), rest::bytes>> <-
           rest,
         total_size <- size,
         <<size::16, topic::bytes-size(size), rest::bytes>> <- rest,
         total_size <- total_size + size,
         <<size::16, payload::bytes-size(size)>> <- rest,
         total_size <- total_size + size do
      with {:ok, properties} <- decode_properties(:will, properties) do
        {:ok, %{properties: properties, topic: topic, payload: payload}, total_size}
      end
    else
      _ -> {:error, :malformed_packet}
    end
  end

  def encode(%ControlPacket.Connect{} = connect) do
    %ControlPacket.Connect{
      username: username,
      password: password,
      will: will,
      will_qos: will_qos,
      will_retain: will_retain,
      clean_start: clean_start,
      clientid: clientid,
      keep_alive: keep_alive,
      properties: properties
    } = connect

    with {:ok, will_qos} <- encode_qos(will_qos),
         {:ok, properties, properties_size} <- encode_properties(@connect, properties),
         {:ok, properties_vbi, properties_vbi_size} <- encode_vbi(properties_size),
         {:ok, encoded_will, will_size} <- encode_will(will),
         {:ok, encoded_username, username_size} <- encode_string(username),
         {:ok, encoded_password, password_size} <- encode_string(password) do
      variable_header =
        <<
          4::16,
          "MQTT",
          5,
          encode_boolean(username)::1,
          encode_boolean(password)::1,
          encode_boolean(will_retain)::1,
          will_qos::2,
          encode_boolean(will)::1,
          encode_boolean(clean_start)::1,
          0::1,
          keep_alive::16
        >>

      variable_header_size = byte_size(variable_header)
      clientid_size = byte_size(clientid)

      size =
        Enum.sum([
          variable_header_size,
          properties_vbi_size,
          properties_size,
          2,
          clientid_size,
          will_size,
          username_size,
          password_size
        ])

      with {:ok, vbi, vbi_size} <- encode_vbi(size) do
        data = [
          <<@connect::4, 0::4>>,
          vbi,
          variable_header,
          properties_vbi,
          properties,
          <<clientid_size::16>>,
          clientid,
          encoded_will,
          encoded_username,
          encoded_password
        ]

        {:ok, data, vbi_size + size + 1}
      end
    end
  end

  def encode(%ControlPacket.Connack{} = connack) do
    %ControlPacket.Connack{
      session_present: session_present,
      reason_code: reason_code,
      properties: properties
    } = connack

    with {:ok, reason_code} <- encode_reason_code(@connack, reason_code),
         {:ok, properties, properties_size} <- encode_properties(@connack, properties),
         {:ok, properties_vbi, properties_vbi_size} <- encode_vbi(properties_size) do
      size = Enum.sum([1, 1, properties_vbi_size, properties_size])

      with {:ok, vbi, vbi_size} <- encode_vbi(size) do
        data = [
          <<@connack::4, 0::4>>,
          vbi,
          <<0::7, encode_boolean(session_present)::1>>,
          reason_code,
          properties_vbi,
          properties
        ]

        {:ok, data, vbi_size + size + 1}
      end
    end
  end

  def encode(%ControlPacket.Publish{} = publish) do
    %ControlPacket.Publish{
      dup_flag: dup_flag,
      qos_level: qos_level,
      retain: retain,
      topic_name: topic_name,
      packet_identifier: packet_identifier,
      properties: properties,
      payload: payload
    } = publish

    with {:ok, packet_identifier, packet_identifier_size} <-
           encode_packet_identifier(qos_level, packet_identifier),
         {:ok, properties, properties_size} <- encode_properties(@publish, properties),
         {:ok, properties_vbi, properties_vbi_size} <- encode_vbi(properties_size),
         {:ok, qos_level} <- encode_qos(qos_level) do
      topic_name_size = byte_size(topic_name)
      payload_size = byte_size(payload)

      size =
        Enum.sum([
          2,
          topic_name_size,
          packet_identifier_size,
          properties_vbi_size,
          properties_size,
          2,
          payload_size
        ])

      with {:ok, vbi, vbi_size} <- encode_vbi(size) do
        data = [
          <<@publish::4, encode_boolean(dup_flag)::1, qos_level::2, encode_boolean(retain)::1>>,
          vbi,
          <<byte_size(topic_name)::16>>,
          topic_name,
          packet_identifier,
          properties_vbi,
          properties,
          <<byte_size(payload)::16>>,
          payload
        ]

        {:ok, data, vbi_size + size + 1}
      end
    end
  end

  def encode(%ControlPacket.Puback{reason_code: :success, properties: map} = puback)
      when map_size(map) === 0 do
    %ControlPacket.Puback{
      packet_identifier: packet_identifier
    } = puback

    {:ok, <<@puback::4, 0::4, 2, packet_identifier::16>>, 4}
  end

  def encode(%ControlPacket.Puback{properties: map} = puback)
      when map_size(map) === 0 do
    %ControlPacket.Puback{
      packet_identifier: packet_identifier,
      reason_code: reason_code
    } = puback

    with {:ok, reason_code} <- encode_reason_code(@puback, reason_code) do
      {:ok, <<@puback::4, 0::4, 3, packet_identifier::16, reason_code>>, 5}
    end
  end

  def encode(%ControlPacket.Puback{} = puback) do
    %ControlPacket.Puback{
      packet_identifier: packet_identifier,
      reason_code: reason_code,
      properties: properties
    } = puback

    with {:ok, properties, properties_size} <- encode_properties(@puback, properties),
         {:ok, properties_vbi, properties_vbi_size} <- encode_vbi(properties_size),
         {:ok, reason_code} <- encode_reason_code(@puback, reason_code) do
      size = Enum.sum([properties_size, properties_vbi_size, 1])

      with {:ok, vbi, vbi_size} <- encode_vbi(size) do
        data = [
          <<@puback::4, 0::4>>,
          vbi,
          <<packet_identifier::16>>,
          reason_code,
          properties_vbi,
          properties
        ]

        {:ok, data, vbi_size + size + 1}
      end
    end
  end

  def encode(%ControlPacket.Pubrec{reason_code: :success, properties: map} = pubrec)
      when map_size(map) === 0 do
    %ControlPacket.Pubrec{
      packet_identifier: packet_identifier
    } = pubrec

    {:ok, <<@pubrec::4, 0::4, 2, packet_identifier::16>>, 4}
  end

  def encode(%ControlPacket.Pubrec{properties: map} = pubrec)
      when map_size(map) === 0 do
    %ControlPacket.Pubrec{
      packet_identifier: packet_identifier,
      reason_code: reason_code
    } = pubrec

    with {:ok, reason_code} <- encode_reason_code(@pubrec, reason_code) do
      {:ok, <<@pubrec::4, 0::4, 3, packet_identifier::16, reason_code>>, 5}
    end
  end

  def encode(%ControlPacket.Pubrec{} = pubrec) do
    %ControlPacket.Pubrec{
      packet_identifier: packet_identifier,
      reason_code: reason_code,
      properties: properties
    } = pubrec

    with {:ok, properties, properties_size} <- encode_properties(@pubrec, properties),
         {:ok, properties_vbi, properties_vbi_size} <- encode_vbi(properties_size),
         {:ok, reason_code} <- encode_reason_code(@pubrec, reason_code) do
      size = Enum.sum([properties_size, properties_vbi_size, 1])

      with {:ok, vbi, vbi_size} <- encode_vbi(size) do
        data = [
          <<@pubrec::4, 0::4>>,
          vbi,
          <<packet_identifier::16>>,
          reason_code,
          properties_vbi,
          properties
        ]

        {:ok, data, vbi_size + size + 1}
      end
    end
  end

  def encode(%ControlPacket.Pubrel{reason_code: :success, properties: map} = pubrel)
      when map_size(map) === 0 do
    %ControlPacket.Pubrel{
      packet_identifier: packet_identifier
    } = pubrel

    {:ok, <<@pubrel::4, 2::4, 2, packet_identifier::16>>, 4}
  end

  def encode(%ControlPacket.Pubrel{properties: map} = pubrel)
      when map_size(map) === 0 do
    %ControlPacket.Pubrel{
      packet_identifier: packet_identifier,
      reason_code: reason_code
    } = pubrel

    with {:ok, reason_code} <- encode_reason_code(@pubrel, reason_code) do
      {:ok, <<@pubrel::4, 2::4, 3, packet_identifier::16, reason_code>>, 5}
    end
  end

  def encode(%ControlPacket.Pubrel{} = pubrel) do
    %ControlPacket.Pubrel{
      packet_identifier: packet_identifier,
      reason_code: reason_code,
      properties: properties
    } = pubrel

    with {:ok, properties, properties_size} <- encode_properties(@pubrel, properties),
         {:ok, properties_vbi, properties_vbi_size} <- encode_vbi(properties_size),
         {:ok, reason_code} <- encode_reason_code(@pubrel, reason_code) do
      size = Enum.sum([properties_size, properties_vbi_size, 1])

      with {:ok, vbi, vbi_size} <- encode_vbi(size) do
        data = [
          <<@pubrel::4, 2::4>>,
          vbi,
          <<packet_identifier::16>>,
          reason_code,
          properties_vbi,
          properties
        ]

        {:ok, data, vbi_size + size + 1}
      end
    end
  end

  def encode(%ControlPacket.Pubcomp{reason_code: :success, properties: map} = pubcomp)
      when map_size(map) === 0 do
    %ControlPacket.Pubcomp{
      packet_identifier: packet_identifier
    } = pubcomp

    {:ok, <<@pubcomp::4, 0::4, 2, packet_identifier::16>>, 4}
  end

  def encode(%ControlPacket.Pubcomp{properties: map} = pubcomp)
      when map_size(map) === 0 do
    %ControlPacket.Pubcomp{
      packet_identifier: packet_identifier,
      reason_code: reason_code
    } = pubcomp

    with {:ok, reason_code} <- encode_reason_code(@pubcomp, reason_code) do
      {:ok, <<@pubcomp::4, 0::4, 3, packet_identifier::16, reason_code>>, 5}
    end
  end

  def encode(%ControlPacket.Pubcomp{} = pubcomp) do
    %ControlPacket.Pubcomp{
      packet_identifier: packet_identifier,
      reason_code: reason_code,
      properties: properties
    } = pubcomp

    with {:ok, properties, properties_size} <- encode_properties(@pubcomp, properties),
         {:ok, properties_vbi, properties_vbi_size} <- encode_vbi(properties_size),
         {:ok, reason_code} <- encode_reason_code(@pubcomp, reason_code) do
      size = Enum.sum([properties_size, properties_vbi_size, 1])

      with {:ok, vbi, vbi_size} <- encode_vbi(size) do
        data = [
          <<@pubcomp::4, 0::4>>,
          vbi,
          <<packet_identifier::16>>,
          reason_code,
          properties_vbi,
          properties
        ]

        {:ok, data, vbi_size + size + 1}
      end
    end
  end

  def encode(%ControlPacket.Subscribe{} = subscribe) do
    %ControlPacket.Subscribe{
      packet_identifier: packet_identifier,
      properties: properties,
      topic_filters: topic_filters
    } = subscribe

    with {:ok, properties, properties_size} <- encode_properties(@subscribe, properties),
         {:ok, properties_vbi, properties_vbi_size} <- encode_vbi(properties_size),
         {:ok, topic_filters, topic_filter_size} <- encode_topic_flag_filters(topic_filters) do
      size = Enum.sum([properties_size, properties_vbi_size, topic_filter_size, 2])

      with {:ok, vbi, vbi_size} <- encode_vbi(size) do
        data = [
          <<@subscribe::4, 2::4>>,
          vbi,
          <<packet_identifier::16>>,
          properties_vbi,
          properties,
          topic_filters
        ]

        {:ok, data, vbi_size + size + 1}
      end
    end
  end

  def encode(%ControlPacket.Suback{} = suback) do
    %ControlPacket.Suback{
      packet_identifier: packet_identifier,
      properties: properties,
      reason_codes: reason_codes
    } = suback

    with {:ok, properties, properties_size} <- encode_properties(@suback, properties),
         {:ok, properties_vbi, properties_vbi_size} <- encode_vbi(properties_size),
         {:ok, reason_codes, reason_codes_size} <- encode_reason_codes(@suback, reason_codes) do
      size = Enum.sum([properties_size, properties_vbi_size, reason_codes_size, 2])

      with {:ok, vbi, vbi_size} <- encode_vbi(size) do
        data = [
          <<@suback::4, 0::4>>,
          vbi,
          <<packet_identifier::16>>,
          properties_vbi,
          properties,
          reason_codes
        ]

        {:ok, data, vbi_size + size + 1}
      end
    end
  end

  def encode(%ControlPacket.Unsubscribe{} = unsubscribe) do
    %ControlPacket.Unsubscribe{
      packet_identifier: packet_identifier,
      properties: properties,
      topic_filters: topic_filters
    } = unsubscribe

    with {:ok, properties, properties_size} <- encode_properties(@unsubscribe, properties),
         {:ok, properties_vbi, properties_vbi_size} <- encode_vbi(properties_size),
         {:ok, topic_filters, topic_filter_size} <- encode_topic_filters(topic_filters) do
      size = Enum.sum([properties_size, properties_vbi_size, topic_filter_size, 2])

      with {:ok, vbi, vbi_size} <- encode_vbi(size) do
        data = [
          <<@unsubscribe::4, 2::4>>,
          vbi,
          <<packet_identifier::16>>,
          properties_vbi,
          properties,
          topic_filters
        ]

        {:ok, data, vbi_size + size + 1}
      end
    end
  end

  def encode(%ControlPacket.Unsuback{} = unsuback) do
    %ControlPacket.Unsuback{
      packet_identifier: packet_identifier,
      properties: properties,
      reason_codes: reason_codes
    } = unsuback

    with {:ok, properties, properties_size} <- encode_properties(@unsuback, properties),
         {:ok, properties_vbi, properties_vbi_size} <- encode_vbi(properties_size),
         {:ok, reason_codes, reason_codes_size} <- encode_reason_codes(@unsuback, reason_codes) do
      size = Enum.sum([properties_size, properties_vbi_size, reason_codes_size, 2])

      with {:ok, vbi, vbi_size} <- encode_vbi(size) do
        data = [
          <<@unsuback::4, 0::4>>,
          vbi,
          <<packet_identifier::16>>,
          properties_vbi,
          properties,
          reason_codes
        ]

        {:ok, data, vbi_size + size + 1}
      end
    end
  end

  def encode(%ControlPacket.Pingreq{}) do
    {:ok, <<@pingreq::4, 0::4, 0>>, 2}
  end

  def encode(%ControlPacket.Pingresp{}) do
    {:ok, <<@pingresp::4, 0::4, 0>>, 2}
  end

  def encode(%ControlPacket.Disconnect{reason_code: :normal_disconnection, properties: %{}}) do
    {:ok, <<@disconnect::4, 0::4, 0>>, 2}
  end

  def encode(%ControlPacket.Disconnect{reason_code: reason_code, properties: %{}}) do
    with {:ok, reason_code} <- encode_reason_code(@disconnect, reason_code) do
      {:ok, <<@disconnect::4, 0::4, 1, reason_code>>, 3}
    end
  end

  def encode(%ControlPacket.Disconnect{} = disconnect) do
    %ControlPacket.Disconnect{
      reason_code: reason_code,
      properties: properties
    } = disconnect

    with {:ok, properties, properties_size} <- encode_properties(@disconnect, properties),
         {:ok, properties_vbi, properties_vbi_size} <- encode_vbi(properties_size),
         {:ok, reason_code} <- encode_reason_code(@disconnect, reason_code) do
      size = Enum.sum([properties_size, properties_vbi_size, 1])

      with {:ok, vbi, vbi_size} <- encode_vbi(size) do
        data = [
          <<@disconnect::4, 0::4>>,
          vbi,
          reason_code,
          properties_vbi,
          properties
        ]

        {:ok, data, vbi_size + size + 1}
      end
    end
  end

  def encode(%ControlPacket.Auth{} = auth) do
    %ControlPacket.Auth{
      reason_code: reason_code,
      properties: properties
    } = auth

    with {:ok, properties, properties_size} <- encode_properties(@auth, properties),
         {:ok, properties_vbi, properties_vbi_size} <- encode_vbi(properties_size),
         {:ok, reason_code} <- encode_reason_code(@auth, reason_code) do
      size = Enum.sum([properties_size, properties_vbi_size, 1])

      with {:ok, vbi, vbi_size} <- encode_vbi(size) do
        data = [
          <<@auth::4, 0::4>>,
          vbi,
          reason_code,
          properties_vbi,
          properties
        ]

        {:ok, data, vbi_size + size + 1}
      end
    end
  end

  defp decode_reason_codes(code, data) do
    decode_reason_codes(code, data, [])
  end

  defp decode_reason_codes(_, <<>>, list), do: {:ok, Enum.reverse(list)}

  defp decode_reason_codes(code, <<data::bytes>>, list) do
    <<reason_code, rest::bytes>> = data
    {:ok, reason_code} = decode_reason_code(code, reason_code)
    decode_reason_codes(code, rest, [reason_code | list])
  end

  defp decode_topic_flag_filters(data) do
    decode_topic_flag_filters(data, [])
  end

  defp decode_topic_flag_filters(<<>>, list), do: {:ok, Enum.reverse(list)}

  defp decode_topic_flag_filters(<<data::bytes>>, list) do
    <<
      length::16,
      topic_filter::bytes-size(length),
      0::2,
      retain_handling::2,
      rap::1,
      nl::1,
      qos::2,
      rest::bytes
    >> = data

    {:ok, retain_handling} = decode_retain_handling(retain_handling)
    {:ok, qos} = decode_qos(qos)

    decode_topic_flag_filters(rest, [
      {topic_filter,
       %{
         retain_handling: retain_handling,
         rap: rap == 1,
         nl: nl == 1,
         qos: qos
       }}
      | list
    ])
  end

  defp decode_topic_filters(data) do
    decode_topic_filters(data, [])
  end

  defp decode_topic_filters(<<>>, list), do: {:ok, Enum.reverse(list)}

  defp decode_topic_filters(<<data::bytes>>, list) do
    <<
      length::16,
      topic_filter::bytes-size(length),
      rest::bytes
    >> = data

    decode_topic_filters(rest, [topic_filter | list])
  end

  defp decode_retain_handling(integer) do
    case integer do
      @send_when_subscribed -> {:ok, :send_when_subscribed}
      @send_if_no_subscription -> {:ok, :send_if_no_subscription}
      @dont_send -> {:ok, :dont_send}
      _ -> {:error, :protocol_error}
    end
  end

  defp decode_vbi(data) do
    decode_vbi(data, 1, 0)
  end

  defp decode_vbi(<<1::1, num::7, rest::bytes>>, multiplier, total) do
    decode_vbi(rest, multiplier <<< 7, total + num * multiplier)
  end

  defp decode_vbi(<<0::1, num::7, _::bytes>>, multiplier, total) do
    size = if total === 0, do: 1, else: trunc(:math.log(total) / :math.log(128)) + 1
    {:ok, total + num * multiplier, size}
  end

  defp decode_vbi(_, _, _), do: {:error, :malformed_packet}

  defp decode_reason_code(code, @success)
       when code in [@connack, @puback, @pubrec, @pubrel, @pubcomp, @unsuback, @auth] do
    {:ok, :success}
  end

  defp decode_reason_code(code, @normal_disconnection) when code in [@disconnect] do
    {:ok, :normal_disconnection}
  end

  defp decode_reason_code(code, @granted_qos_0) when code in [@suback] do
    {:ok, :granted_qos_0}
  end

  defp decode_reason_code(code, @granted_qos_1) when code in [@suback] do
    {:ok, :granted_qos_1}
  end

  defp decode_reason_code(code, @granted_qos_2) when code in [@suback] do
    {:ok, :granted_qos_2}
  end

  defp decode_reason_code(code, @disconnect_with_will_message) when code in [@disconnect] do
    {:ok, :disconnect_with_will_message}
  end

  defp decode_reason_code(code, @no_matching_subscribers) when code in [@puback, @pubrec] do
    {:ok, :no_matching_subscribers}
  end

  defp decode_reason_code(code, @no_subscription_existed) when code in [@unsuback] do
    {:ok, :no_subscription_existed}
  end

  defp decode_reason_code(code, @continue_authentication) when code in [@auth] do
    {:ok, :continue_authentication}
  end

  defp decode_reason_code(code, @re_authenticate) when code in [@auth] do
    {:ok, :re_authenticate}
  end

  defp decode_reason_code(code, @unspecified_error)
       when code in [@connack, @puback, @pubrec, @suback, @unsuback, @disconnect] do
    {:ok, :unspecified_error}
  end

  defp decode_reason_code(code, @malformed_packet)
       when code in [@connack, @disconnect] do
    {:ok, :malformed_packet}
  end

  defp decode_reason_code(code, @protocol_error)
       when code in [@connack, @disconnect] do
    {:ok, :protocol_error}
  end

  defp decode_reason_code(code, @implementation_specific_error)
       when code in [@connack, @puback, @pubrec, @suback, @unsuback, @disconnect] do
    {:ok, :implementation_specific_error}
  end

  defp decode_reason_code(code, @unsupported_protocol_error)
       when code in [@connack] do
    {:ok, :unsupported_protocol_error}
  end

  defp decode_reason_code(code, @client_identifier_not_valid)
       when code in [@connack] do
    {:ok, :client_identifier_not_valid}
  end

  defp decode_reason_code(code, @bad_username_or_password)
       when code in [@connack] do
    {:ok, :bad_username_or_password}
  end

  defp decode_reason_code(code, @not_authorized)
       when code in [@connack, @puback, @pubrec, @suback, @unsuback, @disconnect] do
    {:ok, :not_authorized}
  end

  defp decode_reason_code(code, @server_unavailable) when code in [@connack] do
    {:ok, :server_unavailable}
  end

  defp decode_reason_code(code, @server_busy)
       when code in [@connack, @disconnect] do
    {:ok, :server_busy}
  end

  defp decode_reason_code(code, @banned) when code in [@connack] do
    {:ok, :banned}
  end

  defp decode_reason_code(code, @server_shutting_down) when code in [@disconnect] do
    {:ok, :server_shutting_down}
  end

  defp decode_reason_code(code, @bad_authentication_method)
       when code in [@connack, @disconnect] do
    {:ok, :bad_authentication_method}
  end

  defp decode_reason_code(code, @keep_alive_timeout) when code in [@disconnect] do
    {:ok, :keep_alive_timeout}
  end

  defp decode_reason_code(code, @session_taken_over) when code in [@disconnect] do
    {:ok, :session_taken_over}
  end

  defp decode_reason_code(code, @topic_filter_invalid)
       when code in [@suback, @unsuback, @disconnect] do
    {:ok, :topic_filter_invalid}
  end

  defp decode_reason_code(code, @topic_name_invalid)
       when code in [@connack, @puback, @pubrec, @disconnect] do
    {:ok, :topic_name_invalid}
  end

  defp decode_reason_code(code, @packet_identifier_in_use)
       when code in [@puback, @pubrec, @suback, @unsuback] do
    {:ok, :packet_identifier_in_use}
  end

  defp decode_reason_code(code, @packet_identifier_not_found)
       when code in [@pubrel, @pubcomp] do
    {:ok, :packet_identifier_not_found}
  end

  defp decode_reason_code(code, @receive_maximum_exceeded)
       when code in [@disconnect] do
    {:ok, :receive_maximum_exceeded}
  end

  defp decode_reason_code(code, @topic_alias_invalid)
       when code in [@disconnect] do
    {:ok, :topic_alias_invalid}
  end

  defp decode_reason_code(code, @packet_too_large)
       when code in [@connack, @disconnect] do
    {:ok, :packet_too_large}
  end

  defp decode_reason_code(code, @message_rate_too_high) when code in [@disconnect] do
    {:ok, :message_rate_too_high}
  end

  defp decode_reason_code(code, @quota_exceeded)
       when code in [@connack, @puback, @pubrec, @suback, @disconnect] do
    {:ok, :quota_exceeded}
  end

  defp decode_reason_code(code, @administrative_action) when code in [@disconnect] do
    {:ok, :administrative_action}
  end

  defp decode_reason_code(code, @payload_format_invalid)
       when code in [@connack, @puback, @pubrec, @disconnect] do
    {:ok, :payload_format_invalid}
  end

  defp decode_reason_code(code, @retain_not_supported)
       when code in [@connack, @disconnect] do
    {:ok, :retain_not_supported}
  end

  defp decode_reason_code(code, @qos_not_supported)
       when code in [@connack, @disconnect] do
    {:ok, :qos_not_supported}
  end

  defp decode_reason_code(code, @use_another_server)
       when code in [@connack, @disconnect] do
    {:ok, :use_another_server}
  end

  defp decode_reason_code(code, @server_moved)
       when code in [@connack, @disconnect] do
    {:ok, :server_moved}
  end

  defp decode_reason_code(code, @shared_subscriptions_not_supported)
       when code in [@suback, @disconnect] do
    {:ok, :shared_subscriptions_not_supported}
  end

  defp decode_reason_code(code, @connection_rate_exceeded)
       when code in [@connack, @disconnect] do
    {:ok, :connection_rate_exceeded}
  end

  defp decode_reason_code(code, @maximum_connect_time) when code in [@disconnect] do
    {:ok, :maximum_connect_time}
  end

  defp decode_reason_code(code, @subscription_identifiers_not_supported)
       when code in [@suback, @disconnect] do
    {:ok, :subscription_identifiers_not_supported}
  end

  defp decode_reason_code(code, @wildcard_subscriptions_not_supported)
       when code in [@suback, @disconnect] do
    {:ok, :wildcard_subscriptions_not_supported}
  end

  defp decode_reason_code(_, _) do
    {:error, :malformed_packet}
  end

  defp decode_qos(integer) do
    case integer do
      @at_most_once -> {:ok, :at_most_once}
      @at_least_once -> {:ok, :at_least_once}
      @exactly_once -> {:ok, :exactly_once}
      _ -> {:error, :malformed_packet}
    end
  end

  defp decode_properties(_, <<>>), do: {:ok, %{}}

  defp decode_properties(code, data) do
    decode_properties(code, data, [])
  end

  defp decode_properties(code, <<@payload_format_indicator, rest::bytes>>, list)
       when code in [@publish, :will] do
    <<byte, rest::bytes>> = rest
    decode_properties(code, rest, [{:payload_format_indicator, byte} | list])
  end

  defp decode_properties(code, <<@message_expiry_interval, rest::bytes>>, list)
       when code in [@publish, :will] do
    <<four_byte::32, rest::bytes>> = rest
    decode_properties(code, rest, [{:message_expiry_interval, four_byte} | list])
  end

  defp decode_properties(code, <<@content_type, rest::bytes>>, list)
       when code in [@publish, :will] do
    <<length::16, string::bytes-size(length), rest::bytes>> = rest
    decode_properties(code, rest, [{:content_type, string} | list])
  end

  defp decode_properties(code, <<@response_topic, rest::bytes>>, list)
       when code in [@publish, :will] do
    <<length::16, string::bytes-size(length), rest::bytes>> = rest
    decode_properties(code, rest, [{:response_topic, string} | list])
  end

  defp decode_properties(code, <<@correlation_data, rest::bytes>>, list)
       when code in [@publish, :will] do
    <<length::16, string::bytes-size(length), rest::bytes>> = rest
    decode_properties(code, rest, [{:correlation_data, string} | list])
  end

  defp decode_properties(code, <<@subscription_identifier, rest::bytes>>, list)
       when code in [@publish, @subscribe] do
    {:ok, vbi, size} = decode_vbi(rest)
    <<_::size(size), rest::bytes>> = rest
    decode_properties(code, rest, [{:subscription_identifier, vbi} | list])
  end

  defp decode_properties(code, <<@session_expiry_interval, rest::bytes>>, list)
       when code in [@connect, @connack, @disconnect] do
    <<four_byte::32, rest::bytes>> = rest
    decode_properties(code, rest, [{:session_expiry_interval, four_byte} | list])
  end

  defp decode_properties(code, <<@assigned_client_identifier, rest::bytes>>, list)
       when code in [@connack] do
    <<length::16, string::bytes-size(length), rest::bytes>> = rest
    decode_properties(code, rest, [{:assigned_client_identifier, string} | list])
  end

  defp decode_properties(code, <<@server_keep_alive, rest::bytes>>, list)
       when code in [@connack] do
    <<two_byte::16, rest::bytes>> = rest
    decode_properties(code, rest, [{:server_keep_alive, two_byte} | list])
  end

  defp decode_properties(code, <<@authentication_method, rest::bytes>>, list)
       when code in [@connect, @connack, @auth] do
    <<length::16, string::bytes-size(length), rest::bytes>> = rest
    decode_properties(code, rest, [{:authentication_method, string} | list])
  end

  defp decode_properties(code, <<@authentication_data, rest::bytes>>, list)
       when code in [@connect, @connack, @auth] do
    <<length::16, string::bytes-size(length), rest::bytes>> = rest
    decode_properties(code, rest, [{:authentication_data, string} | list])
  end

  defp decode_properties(code, <<@request_problem_information, rest::bytes>>, list)
       when code in [@connect] do
    <<byte, rest::bytes>> = rest
    decode_properties(code, rest, [{:request_problem_information, byte} | list])
  end

  defp decode_properties(code, <<@will_delay_interval, rest::bytes>>, list)
       when code in [:will] do
    <<four_byte::32, rest::bytes>> = rest
    decode_properties(code, rest, [{:will_delay_interval, four_byte} | list])
  end

  defp decode_properties(code, <<@request_response_information, rest::bytes>>, list)
       when code in [@connect] do
    <<byte, rest::bytes>> = rest
    decode_properties(code, rest, [{:request_response_information, byte} | list])
  end

  defp decode_properties(code, <<@response_information, rest::bytes>>, list)
       when code in [@connack] do
    <<length::16, string::bytes-size(length), rest::bytes>> = rest
    decode_properties(code, rest, [{:response_information, string} | list])
  end

  defp decode_properties(code, <<@server_reference, rest::bytes>>, list)
       when code in [@connack, @disconnect] do
    <<length::16, string::bytes-size(length), rest::bytes>> = rest
    decode_properties(code, rest, [{:server_reference, string} | list])
  end

  defp decode_properties(code, <<@reason_string, rest::bytes>>, list)
       when code not in [@connect, @pingreq, @pingresp, @unsubscribe, :will] do
    <<length::16, string::bytes-size(length), rest::bytes>> = rest
    decode_properties(code, rest, [{:reason_string, string} | list])
  end

  defp decode_properties(code, <<@receive_maximum, rest::bytes>>, list)
       when code in [@connect, @connack] do
    <<two_byte::16, rest::bytes>> = rest
    decode_properties(code, rest, [{:receive_maximum, two_byte} | list])
  end

  defp decode_properties(code, <<@topic_alias_maximum, rest::bytes>>, list)
       when code in [@connect, @connack] do
    <<two_byte::16, rest::bytes>> = rest
    decode_properties(code, rest, [{:topic_alias_maximum, two_byte} | list])
  end

  defp decode_properties(code, <<@topic_alias, rest::bytes>>, list)
       when code in [@publish] do
    <<two_byte::16, rest::bytes>> = rest
    decode_properties(code, rest, [{:topic_alias, two_byte} | list])
  end

  defp decode_properties(code, <<@maximum_qos, rest::bytes>>, list)
       when code in [@connack] do
    <<byte, rest::bytes>> = rest
    decode_properties(code, rest, [{:maximum_qos, byte} | list])
  end

  defp decode_properties(code, <<@retain_available, rest::bytes>>, list)
       when code in [@connack] do
    <<byte, rest::bytes>> = rest
    decode_properties(code, rest, [{:retain_available, byte} | list])
  end

  defp decode_properties(code, <<@user_property, rest::bytes>>, list) do
    <<
      key_length::16,
      key::bytes-size(key_length),
      value_length::16,
      value::bytes-size(value_length),
      rest::bytes
    >> = rest

    decode_properties(code, rest, [{:user_property, {key, value}} | list])
  end

  defp decode_properties(code, <<@maximum_packet_size, rest::bytes>>, list)
       when code in [@connect, @connack] do
    <<four_byte::32, rest::bytes>> = rest
    decode_properties(code, rest, [{:maximum_packet_size, four_byte} | list])
  end

  defp decode_properties(code, <<@wildcard_subscription_available, rest::bytes>>, list)
       when code in [@connack] do
    <<byte, rest::bytes>> = rest
    decode_properties(code, rest, [{:wildcard_subscription_available, byte} | list])
  end

  defp decode_properties(code, <<@subscription_identifier_available, rest::bytes>>, list)
       when code in [@connack] do
    <<byte, rest::bytes>> = rest
    decode_properties(code, rest, [{:subscription_identifier_available, byte} | list])
  end

  defp decode_properties(code, <<@shared_subscription_available, rest::bytes>>, list)
       when code in [@connack] do
    <<byte, rest::bytes>> = rest
    decode_properties(code, rest, [{:shared_subscription_available, byte} | list])
  end

  defp decode_properties(_, <<>>, list) do
    {user_property, list} = Keyword.pop_values(list, :user_property)

    duplicates =
      Enum.reduce_while(list, MapSet.new(), fn {k, _v}, acc ->
        if MapSet.member?(acc, k) do
          {:halt, {:error, :protocol_error}}
        else
          {:cont, MapSet.put(acc, k)}
        end
      end)

    case duplicates do
      {:error, _} = error ->
        error

      _ ->
        list = Enum.into(list, %{}) |> Map.put(:user_property, Enum.into(user_property, %{}))
        {:ok, list}
    end
  end

  defp decode_properties(_, _, _), do: {:error, :malformed_packet}

  defp encode_packet_identifier(:at_most_once, _) do
    {:ok, [], 0}
  end

  defp encode_packet_identifier(_, packet_identifier) do
    {:ok, [<<packet_identifier::16>>], 2}
  end

  defp encode_string(nil) do
    {:ok, [], 0}
  end

  defp encode_string(string) do
    string_size = byte_size(string)

    data = [<<string_size::16>>, string]
    size = string_size + 2

    {:ok, data, size}
  end

  defp encode_will(nil) do
    {:ok, [], 0}
  end

  defp encode_will(will) do
    with %{properties: properties, topic: topic, payload: payload} <- will,
         {:ok, properties, properties_size} <- encode_properties(:will, properties),
         {:ok, vbi, vbi_size} <- encode_vbi(properties_size) do
      topic_size = byte_size(topic)
      payload_size = byte_size(payload)

      data = [vbi, properties, <<topic_size::16>>, topic, <<payload_size::16>>, payload]
      size = Enum.sum([vbi_size, properties_size, 2, topic_size, 2, payload_size])

      {:ok, data, size}
    end
  end

  defp encode_boolean(boolean) do
    (!!boolean && 1) || 0
  end

  defp encode_reason_codes(code, list), do: encode_reason_codes(code, list, [])
  defp encode_reason_codes(_, [], data), do: {:ok, Enum.reverse(data), length(data)}

  defp encode_reason_codes(code, [reason_code | list], data) do
    {:ok, reason_code} = encode_reason_code(code, reason_code)
    encode_reason_codes(code, list, [reason_code | data])
  end

  defp encode_reason_code(code, :success)
       when code in [@connack, @puback, @pubrec, @pubrel, @pubcomp, @unsuback, @auth] do
    {:ok, @success}
  end

  defp encode_reason_code(code, :normal_disconnection) when code in [@disconnect] do
    {:ok, @normal_disconnection}
  end

  defp encode_reason_code(code, :granted_qos_0) when code in [@suback] do
    {:ok, @granted_qos_0}
  end

  defp encode_reason_code(code, :granted_qos_1) when code in [@suback] do
    {:ok, @granted_qos_1}
  end

  defp encode_reason_code(code, :granted_qos_2) when code in [@suback] do
    {:ok, @granted_qos_2}
  end

  defp encode_reason_code(code, :disconnect_with_will_message) when code in [@disconnect] do
    {:ok, @disconnect_with_will_message}
  end

  defp encode_reason_code(code, :no_matching_subscribers) when code in [@puback, @pubrec] do
    {:ok, @no_matching_subscribers}
  end

  defp encode_reason_code(code, :no_subscription_existed) when code in [@unsuback] do
    {:ok, @no_subscription_existed}
  end

  defp encode_reason_code(code, :continue_authentication) when code in [@auth] do
    {:ok, @continue_authentication}
  end

  defp encode_reason_code(code, :re_authenticate) when code in [@auth] do
    {:ok, @re_authenticate}
  end

  defp encode_reason_code(code, :unspecified_error)
       when code in [@connack, @puback, @pubrec, @suback, @unsuback, @disconnect] do
    {:ok, @unspecified_error}
  end

  defp encode_reason_code(code, :malformed_packet)
       when code in [@connack, @disconnect] do
    {:ok, @malformed_packet}
  end

  defp encode_reason_code(code, :protocol_error)
       when code in [@connack, @disconnect] do
    {:ok, @protocol_error}
  end

  defp encode_reason_code(code, :implementation_specific_error)
       when code in [@connack, @puback, @pubrec, @suback, @unsuback, @disconnect] do
    {:ok, @implementation_specific_error}
  end

  defp encode_reason_code(code, :unsupported_protocol_error)
       when code in [@connack] do
    {:ok, @unsupported_protocol_error}
  end

  defp encode_reason_code(code, :client_identifier_not_valid)
       when code in [@connack] do
    {:ok, @client_identifier_not_valid}
  end

  defp encode_reason_code(code, :bad_username_or_password)
       when code in [@connack] do
    {:ok, @bad_username_or_password}
  end

  defp encode_reason_code(code, :not_authorized)
       when code in [@connack, @puback, @pubrec, @suback, @unsuback, @disconnect] do
    {:ok, @not_authorized}
  end

  defp encode_reason_code(code, :server_unavailable) when code in [@connack] do
    {:ok, @server_unavailable}
  end

  defp encode_reason_code(code, :server_busy)
       when code in [@connack, @disconnect] do
    {:ok, @server_busy}
  end

  defp encode_reason_code(code, :banned) when code in [@connack] do
    {:ok, @banned}
  end

  defp encode_reason_code(code, :server_shutting_down) when code in [@disconnect] do
    {:ok, @server_shutting_down}
  end

  defp encode_reason_code(code, :bad_authentication_method)
       when code in [@connack, @disconnect] do
    {:ok, @bad_authentication_method}
  end

  defp encode_reason_code(code, :keep_alive_timeout) when code in [@disconnect] do
    {:ok, @keep_alive_timeout}
  end

  defp encode_reason_code(code, :session_taken_over) when code in [@disconnect] do
    {:ok, @session_taken_over}
  end

  defp encode_reason_code(code, :topic_filter_invalid)
       when code in [@suback, @unsuback, @disconnect] do
    {:ok, @topic_filter_invalid}
  end

  defp encode_reason_code(code, :topic_name_invalid)
       when code in [@connack, @puback, @pubrec, @disconnect] do
    {:ok, @topic_name_invalid}
  end

  defp encode_reason_code(code, :packet_identifier_in_use)
       when code in [@puback, @pubrec, @suback, @unsuback] do
    {:ok, @packet_identifier_in_use}
  end

  defp encode_reason_code(code, :packet_identifier_not_found)
       when code in [@pubrel, @pubcomp] do
    {:ok, @packet_identifier_not_found}
  end

  defp encode_reason_code(code, :receive_maximum_exceeded)
       when code in [@disconnect] do
    {:ok, @receive_maximum_exceeded}
  end

  defp encode_reason_code(code, :topic_alias_invalid)
       when code in [@disconnect] do
    {:ok, @topic_alias_invalid}
  end

  defp encode_reason_code(code, :packet_too_large)
       when code in [@connack, @disconnect] do
    {:ok, @packet_too_large}
  end

  defp encode_reason_code(code, :message_rate_too_high) when code in [@disconnect] do
    {:ok, @message_rate_too_high}
  end

  defp encode_reason_code(code, :quota_exceeded)
       when code in [@connack, @puback, @pubrec, @suback, @disconnect] do
    {:ok, @quota_exceeded}
  end

  defp encode_reason_code(code, :administrative_action) when code in [@disconnect] do
    {:ok, @administrative_action}
  end

  defp encode_reason_code(code, :payload_format_invalid)
       when code in [:connack, @puback, @pubrec, @disconnect] do
    {:ok, @payload_format_invalid}
  end

  defp encode_reason_code(code, :retain_not_supported)
       when code in [@connack, @disconnect] do
    {:ok, @retain_not_supported}
  end

  defp encode_reason_code(code, :qos_not_supported)
       when code in [@connack, @disconnect] do
    {:ok, @qos_not_supported}
  end

  defp encode_reason_code(code, :use_another_server)
       when code in [@connack, @disconnect] do
    {:ok, @use_another_server}
  end

  defp encode_reason_code(code, :server_moved)
       when code in [@connack, @disconnect] do
    {:ok, @server_moved}
  end

  defp encode_reason_code(code, :shared_subscriptions_not_supported)
       when code in [@suback, @disconnect] do
    {:ok, @shared_subscriptions_not_supported}
  end

  defp encode_reason_code(code, :connection_rate_exceeded)
       when code in [@connack, @disconnect] do
    {:ok, @connection_rate_exceeded}
  end

  defp encode_reason_code(code, :maximum_connect_time) when code in [@disconnect] do
    {:ok, @maximum_connect_time}
  end

  defp encode_reason_code(code, :subscription_identifiers_not_supported)
       when code in [@suback, @disconnect] do
    {:ok, @subscription_identifiers_not_supported}
  end

  defp encode_reason_code(code, :wildcard_subscriptions_not_supported)
       when code in [@suback, @disconnect] do
    {:ok, @wildcard_subscriptions_not_supported}
  end

  defp encode_reason_code(_, _), do: {:error, :malformed_packet}

  defp encode_vbi(0), do: {:ok, [0], 1}
  defp encode_vbi(data), do: encode_vbi(data, [])

  defp encode_vbi(0, data), do: {:ok, Enum.reverse(data), length(data)}

  defp encode_vbi(integer, data) do
    encoded_byte = integer &&& 127
    integer = integer >>> 7

    if integer > 0 do
      encode_vbi(integer, [<<encoded_byte ||| 128>> | data])
    else
      encode_vbi(integer, [<<encoded_byte>> | data])
    end
  end

  defp encode_topic_flag_filters(list), do: encode_topic_flag_filters(list, [], 0)
  defp encode_topic_flag_filters([], data, size), do: {:ok, Enum.reverse(data), size}

  defp encode_topic_flag_filters([{topic_filter, sub_opts} | list], data, size) do
    %{retain_handling: retain_handling, rap: rap, nl: nl, qos: qos} = sub_opts

    with {:ok, retain_handling} <- encode_retain_handling(retain_handling),
         {:ok, qos} <- encode_qos(qos) do
      topic_filter_size = byte_size(topic_filter)

      data = [
        [
          <<topic_filter_size::16>>,
          topic_filter,
          <<0::2, retain_handling::2, encode_boolean(rap)::1, encode_boolean(nl)::1, qos::2>>
        ]
        | data
      ]

      size = Enum.sum([size, 2, topic_filter_size, 1])

      encode_topic_flag_filters(list, data, size)
    end
  end

  defp encode_topic_filters(list), do: encode_topic_filters(list, [], 0)
  defp encode_topic_filters([], data, size), do: {:ok, Enum.reverse(data), size}

  defp encode_topic_filters([topic_filter | list], data, size) do
    topic_filter_size = byte_size(topic_filter)

    data = [[<<topic_filter_size::16>>, topic_filter] | data]

    size = Enum.sum([size, 2, topic_filter_size])

    encode_topic_filters(list, data, size)
  end

  defp encode_retain_handling(retain_handling) do
    case retain_handling do
      :send_when_subscribed -> {:ok, @send_when_subscribed}
      :send_if_no_subscription -> {:ok, @send_if_no_subscription}
      :dont_send -> {:ok, @dont_send}
      _ -> {:error, :protocol_error}
    end
  end

  defp encode_qos(integer) do
    case integer do
      :at_most_once -> {:ok, @at_most_once}
      :at_least_once -> {:ok, @at_least_once}
      :exactly_once -> {:ok, @exactly_once}
      _ -> {:error, :malformed_packet}
    end
  end

  defp encode_properties(_, map) when map_size(map) === 0, do: {:ok, [], 0}

  defp encode_properties(code, properties) do
    {user_property, properties} = Map.pop(properties, :user_property)

    keys =
      Enum.reduce_while(properties, MapSet.new(), fn {k, _v}, acc ->
        if MapSet.member?(acc, k) do
          {:halt, {:error, :protocol_error}}
        else
          {:cont, MapSet.put(acc, k)}
        end
      end)

    case keys do
      {:error, _} = error ->
        error

      _ ->
        properties =
          Enum.reduce(user_property, Enum.to_list(properties), fn up, properties ->
            [{:user_property, up} | properties]
          end)

        encode_properties(code, properties, [], 0)
    end
  end

  defp encode_properties(code, [{:payload_format_indicator, byte} | list], data, size)
       when code in [@publish, :will] do
    bytes = <<@payload_format_indicator, byte>>
    encode_properties(code, list, [bytes | data], size + byte_size(bytes))
  end

  defp encode_properties(code, [{:message_expiry_interval, four_byte} | list], data, size)
       when code in [@publish, :will] do
    bytes = <<@message_expiry_interval, four_byte::32>>
    encode_properties(code, list, [bytes | data], size + byte_size(bytes))
  end

  defp encode_properties(code, [{:content_type, string} | list], data, size)
       when code in [@publish, :will] do
    bytes = <<@content_type, byte_size(string)::16, string::bytes>>
    encode_properties(code, list, [bytes | data], size + byte_size(bytes))
  end

  defp encode_properties(code, [{:response_topic, string} | list], data, size)
       when code in [@publish, :will] do
    bytes = <<@response_topic, byte_size(string)::16, string::bytes>>
    encode_properties(code, list, [bytes | data], size + byte_size(bytes))
  end

  defp encode_properties(code, [{:correlation_data, string} | list], data, size) do
    bytes = <<@correlation_data, byte_size(string)::16, string::bytes>>
    encode_properties(code, list, [bytes | data], size + byte_size(bytes))
  end

  defp encode_properties(code, [{:subscription_identifier, vbi} | list], data, size)
       when code in [@publish, @subscribe] do
    {:ok, vbi, vbi_size} = encode_vbi(vbi)
    bytes = [@subscription_identifier, vbi]
    encode_properties(code, list, [bytes | data], size + vbi_size + 1)
  end

  defp encode_properties(code, [{:session_expiry_interval, four_byte} | list], data, size)
       when code in [@connect, @connack, @disconnect] do
    bytes = <<@session_expiry_interval, four_byte::32>>
    encode_properties(code, list, [bytes | data], size + byte_size(bytes))
  end

  defp encode_properties(code, [{:assigned_client_identifier, string} | list], data, size)
       when code in [@connack] do
    bytes = <<@assigned_client_identifier, byte_size(string)::16, string::bytes>>
    encode_properties(code, list, [bytes | data], size + byte_size(bytes))
  end

  defp encode_properties(code, [{:server_keep_alive, two_byte} | list], data, size)
       when code in [@connack] do
    bytes = <<@server_keep_alive, two_byte::16>>
    encode_properties(code, list, [bytes | data], size + byte_size(bytes))
  end

  defp encode_properties(code, [{:authentication_method, string} | list], data, size)
       when code in [@connect, @connack, @auth] do
    bytes = <<@authentication_method, byte_size(string)::16, string::bytes>>
    encode_properties(code, list, [bytes | data], size + byte_size(bytes))
  end

  defp encode_properties(code, [{:authentication_data, string} | list], data, size)
       when code in [@connect, @connack, @auth] do
    bytes = <<@authentication_data, byte_size(string)::16, string::bytes>>
    encode_properties(code, list, [bytes | data], size + byte_size(bytes))
  end

  defp encode_properties(code, [{:request_problem_information, byte} | list], data, size)
       when code in [@connect] do
    bytes = <<@request_problem_information, byte>>
    encode_properties(code, list, [bytes | data], size + byte_size(bytes))
  end

  defp encode_properties(code, [{:will_delay_interval, four_byte} | list], data, size)
       when code in [:will] do
    bytes = <<@will_delay_interval, four_byte::32>>
    encode_properties(code, list, [bytes | data], size + byte_size(bytes))
  end

  defp encode_properties(code, [{:request_response_information, byte} | list], data, size)
       when code in [@connect] do
    bytes = <<@request_response_information, byte>>
    encode_properties(code, list, [bytes | data], size + byte_size(bytes))
  end

  defp encode_properties(code, [{:response_information, string} | list], data, size)
       when code in [@connack] do
    bytes = <<@response_information, byte_size(string)::16, string::bytes>>
    encode_properties(code, list, [bytes | data], size + byte_size(bytes))
  end

  defp encode_properties(code, [{:server_reference, string} | list], data, size)
       when code in [@connack, @disconnect] do
    bytes = <<@server_reference, byte_size(string)::16, string::bytes>>
    encode_properties(code, list, [bytes | data], size + byte_size(bytes))
  end

  defp encode_properties(code, [{:reason_string, string} | list], data, size)
       when code not in [@connect, @pingreq, @pingresp, @unsubscribe, :will] do
    bytes = <<@reason_string, byte_size(string)::16, string::bytes>>
    encode_properties(code, list, [bytes | data], size + byte_size(bytes))
  end

  defp encode_properties(code, [{:receive_maximum, two_byte} | list], data, size)
       when code in [@connect, @connack] do
    bytes = <<@receive_maximum, two_byte::16>>
    encode_properties(code, list, [bytes | data], size + byte_size(bytes))
  end

  defp encode_properties(code, [{:topic_alias_maximum, two_byte} | list], data, size)
       when code in [@connect, @connack] do
    bytes = <<@topic_alias_maximum, two_byte::16>>
    encode_properties(code, list, [bytes | data], size + byte_size(bytes))
  end

  defp encode_properties(code, [{:topic_alias, two_byte} | list], data, size)
       when code in [@publish] do
    bytes = <<@topic_alias, two_byte::16>>
    encode_properties(code, list, [bytes | data], size + byte_size(bytes))
  end

  defp encode_properties(code, [{:maximum_qos, byte} | list], data, size)
       when code in [@connack] do
    bytes = <<@maximum_qos, byte>>
    encode_properties(code, list, [bytes | data], size + byte_size(bytes))
  end

  defp encode_properties(code, [{:retain_available, byte} | list], data, size)
       when code in [@connack] do
    bytes = <<@retain_available, byte>>
    encode_properties(code, list, [bytes | data], size + byte_size(bytes))
  end

  defp encode_properties(code, [{:user_property, {key, value}} | list], data, size) do
    bytes = <<@user_property, byte_size(key)::16, key::bytes, byte_size(value)::16, value::bytes>>
    encode_properties(code, list, [bytes | data], size + byte_size(bytes))
  end

  defp encode_properties(code, [{:maximum_packet_size, four_byte} | list], data, size)
       when code in [@connect, @connack] do
    bytes = <<@maximum_packet_size, four_byte::32>>
    encode_properties(code, list, [bytes | data], size + byte_size(bytes))
  end

  defp encode_properties(code, [{:wildcard_subscription_available, byte} | list], data, size)
       when code in [@connack] do
    bytes = <<@wildcard_subscription_available, byte>>
    encode_properties(code, list, [bytes | data], size + byte_size(bytes))
  end

  defp encode_properties(code, [{:subscription_identifier_available, byte} | list], data, size)
       when code in [@connack] do
    bytes = <<@subscription_identifier_available, byte>>
    encode_properties(code, list, [bytes | data], size + byte_size(bytes))
  end

  defp encode_properties(code, [{:shared_subscription_available, byte} | list], data, size)
       when code in [@connack] do
    bytes = <<@shared_subscription_available, byte>>
    encode_properties(code, list, [bytes | data], size + byte_size(bytes))
  end

  defp encode_properties(_, [], data, size), do: {:ok, data, size}

  defp encode_properties(_, _, _, _), do: {:error, :malformed_packet}
end
