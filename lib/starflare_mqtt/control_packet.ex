defmodule StarflareMqtt.ControlPacket do
  @moduledoc false

  alias StarflareMqtt.ControlPacket
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

  def decode(<<@connect::4, 0::4, rest::binary>>) do
    {:ok, vbi} = decode_vbi(rest)
    size = vbi_size(rest)
    <<_::binary-size(size), rest::binary-size(vbi)>> = rest

    <<
      4::16,
      "MQTT",
      5,
      username_flag::1,
      password_flag::1,
      will_retain::1,
      will_qos::2,
      will_flag::1,
      clean_start::1,
      0::1,
      keep_alive::16,
      rest::binary
    >> = rest

    {:ok, will_qos} = decode_qos(will_qos)

    {:ok, vbi} = decode_vbi(rest)
    size = vbi_size(rest)
    <<_::binary-size(size), properties::binary-size(vbi), rest::binary>> = rest

    {:ok, properties} = decode_properties(@connect, properties)

    <<size::16, clientid::binary-size(size), rest::binary>> = rest

    {will, size} =
      if will_flag == 1 do
        {:ok, vbi} = decode_vbi(rest)
        size = vbi_size(rest)
        <<_::binary-size(size), properties::binary-size(vbi), rest::binary>> = rest
        {:ok, properties} = decode_properties(:will, properties)
        total_size = size

        <<size::16, topic::binary-size(size), rest::binary>> = rest
        total_size = total_size + size

        <<size::16, payload::binary-size(size)>> = rest
        total_size = total_size + size

        {%{properties: properties, topic: topic, payload: payload}, total_size}
      else
        {nil, 0}
      end

    <<_::binary-size(size), rest::binary>> = rest

    {username, size} =
      if username_flag == 1 do
        <<size::16, username::binary-size(size)>> = rest
        {username, size}
      else
        {nil, 0}
      end

    <<_::binary-size(size), rest::binary>> = rest

    {password, _} =
      if password_flag == 1 do
        <<size::16, password::binary-size(size)>> = rest
        {password, size}
      else
        {nil, 0}
      end

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
    }
  end

  def decode(<<@connack::4, 0::4, rest::binary>>) do
    {:ok, vbi} = decode_vbi(rest)
    size = vbi_size(rest)
    <<_::binary-size(size), rest::binary-size(vbi)>> = rest

    <<0::7, session_present::1, reason_code, rest::binary>> = rest

    {:ok, reason_code} = decode_reason_code(@connack, reason_code)

    {:ok, vbi} = decode_vbi(rest)
    size = vbi_size(rest)
    <<_::binary-size(size), properties::binary-size(vbi)>> = rest
    {:ok, properties} = decode_properties(@connack, properties)

    %ControlPacket.Connack{
      session_present: session_present == 1,
      reason_code: reason_code,
      properties: properties
    }
  end

  def decode(<<@publish::4, flags::bitstring-4, rest::binary>>) do
    {:ok, vbi} = decode_vbi(rest)
    size = vbi_size(rest)
    <<_::binary-size(size), rest::binary-size(vbi)>> = rest

    <<dup_flag::1, qos_level::2, retain::1>> = flags
    {:ok, qos_level} = decode_qos(qos_level)

    <<length::16, topic_name::binary-size(length), packet_identifier::16, rest::binary>> = rest

    {:ok, vbi} = decode_vbi(rest)
    size = vbi_size(rest)
    <<_::binary-size(size), properties::binary-size(vbi), payload::binary>> = rest
    {:ok, properties} = decode_properties(@publish, properties)

    %ControlPacket.Publish{
      dup_flag: dup_flag == 1,
      qos_level: qos_level,
      retain: retain == 1,
      topic_name: topic_name,
      packet_identifier: packet_identifier,
      properties: properties,
      payload: payload
    }
  end

  def decode(<<@puback::4, 0::4, rest::binary>>) do
    {:ok, vbi} = decode_vbi(rest)
    size = vbi_size(rest)
    <<_::binary-size(size), rest::binary-size(vbi)>> = rest

    <<packet_identifier::16, reason_code, rest::binary>> = rest

    {:ok, reason_code} = decode_reason_code(@puback, reason_code)

    {:ok, vbi} = decode_vbi(rest)
    size = vbi_size(rest)
    <<_::binary-size(size), properties::binary-size(vbi)>> = rest
    {:ok, properties} = decode_properties(@puback, properties)

    %ControlPacket.Puback{
      packet_identifier: packet_identifier,
      reason_code: reason_code,
      properties: properties
    }
  end

  def decode(<<@pubrec::4, 0::4, rest::binary>>) do
    {:ok, vbi} = decode_vbi(rest)
    size = vbi_size(rest)
    <<_::binary-size(size), rest::binary-size(vbi)>> = rest

    <<packet_identifier::16, reason_code, rest::binary>> = rest

    {:ok, reason_code} = decode_reason_code(@pubrec, reason_code)

    {:ok, vbi} = decode_vbi(rest)
    size = vbi_size(rest)
    <<_::binary-size(size), properties::binary-size(vbi)>> = rest
    {:ok, properties} = decode_properties(@pubrec, properties)

    %ControlPacket.Pubrec{
      packet_identifier: packet_identifier,
      reason_code: reason_code,
      properties: properties
    }
  end

  def decode(<<@pubrel::4, 2::4, rest::binary>>) do
    {:ok, vbi} = decode_vbi(rest)
    size = vbi_size(rest)
    <<_::binary-size(size), rest::binary-size(vbi)>> = rest

    <<packet_identifier::16, reason_code, rest::binary>> = rest

    {:ok, reason_code} = decode_reason_code(@pubrel, reason_code)

    {:ok, vbi} = decode_vbi(rest)
    size = vbi_size(rest)
    <<_::binary-size(size), properties::binary-size(vbi)>> = rest
    {:ok, properties} = decode_properties(@pubrel, properties)

    %ControlPacket.Pubrel{
      packet_identifier: packet_identifier,
      reason_code: reason_code,
      properties: properties
    }
  end

  def decode(<<@pubcomp::4, 0::4, rest::binary>>) do
    {:ok, vbi} = decode_vbi(rest)
    size = vbi_size(rest)
    <<_::binary-size(size), rest::binary-size(vbi)>> = rest

    <<packet_identifier::16, reason_code, rest::binary>> = rest

    {:ok, reason_code} = decode_reason_code(@pubcomp, reason_code)

    {:ok, vbi} = decode_vbi(rest)
    size = vbi_size(rest)
    <<_::binary-size(size), properties::binary-size(vbi)>> = rest
    {:ok, properties} = decode_properties(@pubcomp, properties)

    %ControlPacket.Pubcomp{
      packet_identifier: packet_identifier,
      reason_code: reason_code,
      properties: properties
    }
  end

  def decode(<<@subscribe::4, 2::4, rest::binary>>) do
    {:ok, vbi} = decode_vbi(rest)
    size = vbi_size(rest)
    <<_::binary-size(size), rest::binary-size(vbi)>> = rest

    <<packet_identifier::16, rest::binary>> = rest

    {:ok, vbi} = decode_vbi(rest)
    size = vbi_size(rest)
    <<_::binary-size(size), properties::binary-size(vbi), rest::binary>> = rest
    {:ok, properties} = decode_properties(@subscribe, properties)

    {:ok, topic_filters} = decode_topic_filters(rest, [])

    %ControlPacket.Subscribe{
      packet_identifier: packet_identifier,
      properties: properties,
      topic_filters: topic_filters
    }
  end

  def decode(<<@suback::4, 0::4, rest::binary>>) do
    {:ok, vbi} = decode_vbi(rest)
    size = vbi_size(rest)
    <<_::binary-size(size), rest::binary-size(vbi)>> = rest

    <<packet_identifier::16, rest::binary>> = rest

    {:ok, vbi} = decode_vbi(rest)
    size = vbi_size(rest)
    <<_::binary-size(size), properties::binary-size(vbi), rest::binary>> = rest
    {:ok, properties} = decode_properties(@suback, properties)

    {:ok, reason_codes} = decode_reason_codes(@suback, rest, [])

    %ControlPacket.Suback{
      packet_identifier: packet_identifier,
      properties: properties,
      reason_codes: reason_codes
    }
  end

  def decode(<<@unsubscribe::4, 2::4, rest::binary>>) do
    {:ok, vbi} = decode_vbi(rest)
    size = vbi_size(rest)
    <<_::binary-size(size), rest::binary-size(vbi)>> = rest

    <<packet_identifier::16, rest::binary>> = rest

    {:ok, vbi} = decode_vbi(rest)
    size = vbi_size(rest)
    <<_::binary-size(size), properties::binary-size(vbi), rest::binary>> = rest
    {:ok, properties} = decode_properties(@unsubscribe, properties)

    {:ok, topic_filters} = decode_topic_filters(rest, [])

    %ControlPacket.Unsubscribe{
      packet_identifier: packet_identifier,
      properties: properties,
      topic_filters: topic_filters
    }
  end

  def decode(<<@unsuback::4, 0::4, rest::binary>>) do
    {:ok, vbi} = decode_vbi(rest)
    size = vbi_size(rest)
    <<_::binary-size(size), rest::binary-size(vbi)>> = rest

    <<packet_identifier::16, rest::binary>> = rest

    {:ok, vbi} = decode_vbi(rest)
    size = vbi_size(rest)
    <<_::binary-size(size), properties::binary-size(vbi), rest::binary>> = rest
    {:ok, properties} = decode_properties(@unsuback, properties)

    {:ok, reason_codes} = decode_reason_codes(@unsuback, rest, [])

    %ControlPacket.Unsuback{
      packet_identifier: packet_identifier,
      properties: properties,
      reason_codes: reason_codes
    }
  end

  def decode(<<@pingreq::4, 0::4, 0>>) do
    %ControlPacket.Pingreq{}
  end

  def decode(<<@pingresp::4, 0::4, 0>>) do
    %ControlPacket.Pingresp{}
  end

  def decode(<<@disconnect::4, 0::4>>) do
    %ControlPacket.Disconnect{reason_code: :success}
  end

  def decode(<<@disconnect::4, 0::4, rest::binary>>) do
    {:ok, vbi} = decode_vbi(rest)
    size = vbi_size(rest)
    <<_::binary-size(size), rest::binary-size(vbi)>> = rest

    <<reason_code, rest::binary>> = rest
    {:ok, reason_code} = decode_reason_code(@disconnect, reason_code)

    {:ok, vbi} = decode_vbi(rest)
    size = vbi_size(rest)
    <<_::binary-size(size), properties::binary-size(vbi)>> = rest
    {:ok, properties} = decode_properties(@disconnect, properties)

    %ControlPacket.Disconnect{reason_code: reason_code, properties: properties}
  end

  def decode(<<@auth::4, 0::4, rest::binary>>) do
    {:ok, vbi} = decode_vbi(rest)
    size = vbi_size(rest)
    <<_::binary-size(size), rest::binary-size(vbi)>> = rest

    <<reason_code, rest::binary>> = rest
    {:ok, reason_code} = decode_reason_code(@auth, reason_code)

    {:ok, vbi} = decode_vbi(rest)
    size = vbi_size(rest)
    <<_::binary-size(size), properties::binary-size(vbi)>> = rest
    {:ok, properties} = decode_properties(@auth, properties)

    %ControlPacket.Auth{reason_code: reason_code, properties: properties}
  end

  def decode(_), do: {:error, :malformed_packet}

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

    {:ok, will_qos} = encode_qos(will_qos)
    {:ok, properties} = encode_properties(@connect, properties)
    {:ok, vbi} = encode_vbi(byte_size(properties))

    data = <<
      encode_boolean(username)::1,
      encode_boolean(password)::1,
      encode_boolean(will_retain)::1,
      will_qos::2,
      encode_boolean(will)::1,
      encode_boolean(clean_start)::1,
      0::1,
      keep_alive::16,
      vbi::binary,
      properties::binary,
      byte_size(clientid)::16,
      clientid::binary
    >>

    data =
      if will do
        %{properties: properties, topic: topic, payload: payload} = will

        {:ok, properties} = encode_properties(:will, properties)
        {:ok, vbi} = encode_vbi(byte_size(properties))

        data <>
          <<
            vbi::binary,
            properties::binary,
            byte_size(topic)::16,
            topic::binary,
            byte_size(payload)::16,
            payload::binary
          >>
      else
        data
      end

    data =
      if username,
        do: data <> <<byte_size(username)::16, username::binary>>,
        else: data

    data =
      if password,
        do: data <> <<byte_size(password)::16, password::binary>>,
        else: data

    data = <<4::16, "MQTT", 5, data::binary>>

    {:ok, vbi} = encode_vbi(byte_size(data))

    <<@connect::4, 0::4, vbi::binary, data::binary>>
  end

  def encode(%ControlPacket.Connack{} = connack) do
    %ControlPacket.Connack{
      session_present: session_present,
      reason_code: reason_code,
      properties: properties
    } = connack

    {:ok, reason_code} = encode_reason_code(@connack, reason_code)

    {:ok, properties} = encode_properties(@connack, properties)
    {:ok, vbi} = encode_vbi(byte_size(properties))

    data = <<
      0::7,
      encode_boolean(session_present)::1,
      reason_code,
      vbi::binary,
      properties::binary
    >>

    {:ok, vbi} = encode_vbi(byte_size(data))

    <<@connack::4, 0::4, vbi::binary, data::binary>>
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

    data = <<
      byte_size(topic_name)::16,
      topic_name::binary
    >>

    if qos_level !== :at_most_once,
      do: data <> <<packet_identifier::16>>,
      else: data

    {:ok, properties} = encode_properties(@publish, properties)
    {:ok, vbi} = encode_vbi(byte_size(properties))

    data =
      data <>
        <<
          vbi::binary,
          properties::binary,
          byte_size(payload)::16,
          payload::binary
        >>

    {:ok, vbi} = encode_vbi(byte_size(data))
    {:ok, qos_level} = encode_qos(qos_level)

    <<
      @publish::4,
      encode_boolean(dup_flag)::1,
      qos_level::2,
      encode_boolean(retain)::1,
      vbi::binary,
      data::binary
    >>
  end

  def encode(%ControlPacket.Puback{} = puback) do
    %ControlPacket.Puback{
      packet_identifier: packet_identifier,
      reason_code: reason_code,
      properties: properties
    } = puback

    {:ok, properties} = encode_properties(@puback, properties)
    {:ok, vbi} = encode_vbi(byte_size(properties))
    {:ok, reason_code} = encode_reason_code(@puback, reason_code)

    data = <<packet_identifier::16, reason_code, vbi::binary, properties::binary>>

    {:ok, vbi} = encode_vbi(byte_size(data))

    <<@puback::4, 0::4, vbi::binary, data::binary>>
  end

  def encode(%ControlPacket.Pubrec{} = pubrec) do
    %ControlPacket.Pubrec{
      packet_identifier: packet_identifier,
      reason_code: reason_code,
      properties: properties
    } = pubrec

    {:ok, properties} = encode_properties(@pubrec, properties)
    {:ok, vbi} = encode_vbi(byte_size(properties))
    {:ok, reason_code} = encode_reason_code(@pubrec, reason_code)

    data = <<packet_identifier::16, reason_code, vbi::binary, properties::binary>>

    {:ok, vbi} = encode_vbi(byte_size(data))

    <<@pubrec::4, 0::4, vbi::binary, data::binary>>
  end

  def encode(%ControlPacket.Pubrel{} = pubrel) do
    %ControlPacket.Pubrel{
      packet_identifier: packet_identifier,
      reason_code: reason_code,
      properties: properties
    } = pubrel

    {:ok, properties} = encode_properties(@pubrel, properties)
    {:ok, vbi} = encode_vbi(byte_size(properties))
    {:ok, reason_code} = encode_reason_code(@pubrel, reason_code)

    data = <<packet_identifier::16, reason_code, vbi::binary, properties::binary>>

    {:ok, vbi} = encode_vbi(byte_size(data))

    <<@pubrel::4, 2::4, vbi::binary, data::binary>>
  end

  def encode(%ControlPacket.Pubcomp{} = pubcomp) do
    %ControlPacket.Pubcomp{
      packet_identifier: packet_identifier,
      reason_code: reason_code,
      properties: properties
    } = pubcomp

    {:ok, properties} = encode_properties(@pubcomp, properties)
    {:ok, vbi} = encode_vbi(byte_size(properties))
    {:ok, reason_code} = encode_reason_code(@pubcomp, reason_code)

    data = <<packet_identifier::16, reason_code, vbi::binary, properties::binary>>

    {:ok, vbi} = encode_vbi(byte_size(data))

    <<@pubcomp::4, 0::4, vbi::binary, data::binary>>
  end

  def encode(%ControlPacket.Subscribe{} = subscribe) do
    %ControlPacket.Subscribe{
      packet_identifier: packet_identifier,
      properties: properties,
      topic_filters: topic_filters
    } = subscribe

    {:ok, properties} = encode_properties(@subscribe, properties)
    {:ok, vbi} = encode_vbi(byte_size(properties))
    {:ok, topic_filters} = encode_topic_filters(topic_filters)

    data = <<packet_identifier::16, vbi::binary, properties::binary, topic_filters::binary>>

    {:ok, vbi} = encode_vbi(byte_size(data))

    <<@subscribe::4, 2::4, vbi::binary, data::binary>>
  end

  def encode(%ControlPacket.Suback{} = suback) do
    %ControlPacket.Suback{
      packet_identifier: packet_identifier,
      properties: properties,
      reason_codes: reason_codes
    } = suback

    {:ok, properties} = encode_properties(@suback, properties)
    {:ok, vbi} = encode_vbi(byte_size(properties))
    {:ok, reason_codes} = encode_reason_codes(@suback, reason_codes)

    data = <<packet_identifier::16, vbi::binary, properties::binary, reason_codes::binary>>

    {:ok, vbi} = encode_vbi(byte_size(data))

    <<@suback::4, 0::4, vbi::binary, data::binary>>
  end

  def encode(%ControlPacket.Unsubscribe{} = unsubscribe) do
    %ControlPacket.Unsubscribe{
      packet_identifier: packet_identifier,
      properties: properties,
      topic_filters: topic_filters
    } = unsubscribe

    {:ok, properties} = encode_properties(@unsubscribe, properties)
    {:ok, vbi} = encode_vbi(byte_size(properties))
    {:ok, topic_filters} = encode_topic_filters(topic_filters)

    data = <<packet_identifier::16, vbi::binary, properties::binary, topic_filters::binary>>

    {:ok, vbi} = encode_vbi(byte_size(data))

    <<@unsubscribe::4, 2::4, vbi::binary, data::binary>>
  end

  def encode(%ControlPacket.Unsuback{} = unsuback) do
    %ControlPacket.Unsuback{
      packet_identifier: packet_identifier,
      properties: properties,
      reason_codes: reason_codes
    } = unsuback

    {:ok, properties} = encode_properties(@unsuback, properties)
    {:ok, vbi} = encode_vbi(byte_size(properties))
    {:ok, reason_codes} = encode_reason_codes(@unsuback, reason_codes)

    data = <<packet_identifier::16, vbi::binary, properties::binary, reason_codes::binary>>

    {:ok, vbi} = encode_vbi(byte_size(data))

    <<@unsuback::4, 0::4, vbi::binary, data::binary>>
  end

  def encode(%ControlPacket.Disconnect{} = disconnect) do
    %ControlPacket.Disconnect{
      reason_code: reason_code,
      properties: properties
    } = disconnect

    {:ok, properties} = encode_properties(@disconnect, properties)
    {:ok, vbi} = encode_vbi(byte_size(properties))
    {:ok, reason_code} = encode_reason_code(@disconnect, reason_code)

    data = <<reason_code, vbi::binary, properties::binary>>

    {:ok, vbi} = encode_vbi(byte_size(data))

    <<@disconnect::4, 0::4, vbi::binary, data::binary>>
  end

  def encode(%ControlPacket.Auth{} = auth) do
    %ControlPacket.Auth{
      reason_code: reason_code,
      properties: properties
    } = auth

    {:ok, properties} = encode_properties(@auth, properties)
    {:ok, vbi} = encode_vbi(byte_size(properties))
    {:ok, reason_code} = encode_reason_code(@auth, reason_code)

    data = <<reason_code, vbi::binary, properties::binary>>

    {:ok, vbi} = encode_vbi(byte_size(data))

    <<@auth::4, 0::4, vbi::binary, data::binary>>
  end

  def encode(%ControlPacket.Pingreq{}) do
    <<@pingreq::4, 0::4, 0>>
  end

  def encode(%ControlPacket.Pingresp{}) do
    <<@pingresp::4, 0::4, 0>>
  end

  defp encode_boolean(boolean) do
    (!!boolean && 1) || 0
  end

  defp encode_reason_codes(code, list), do: encode_reason_codes(code, list, <<>>)
  defp encode_reason_codes(_, [], data), do: {:ok, data}

  defp encode_reason_codes(code, [reason_code | list], data) do
    {:ok, reason_code} = encode_reason_code(code, reason_code)
    encode_reason_codes(code, list, data <> <<reason_code>>)
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

  defp encode_vbi(0), do: {:ok, <<0>>}
  defp encode_vbi(data), do: encode_vbi(data, <<>>)

  defp encode_vbi(0, data), do: {:ok, data}

  defp encode_vbi(integer, data) do
    encoded_byte = integer &&& 127
    integer = integer >>> 7

    if integer > 0 do
      encode_vbi(integer, data <> <<encoded_byte ||| 128>>)
    else
      encode_vbi(integer, data <> <<encoded_byte>>)
    end
  end

  defp encode_topic_filters(list), do: encode_topic_filters(list, <<>>)
  defp encode_topic_filters([], data), do: {:ok, data}

  defp encode_topic_filters([{topic_filter, sub_opts} | list], data) do
    %{retain_handling: retain_handling, rap: rap, nl: nl, qos: qos} = sub_opts
    {:ok, retain_handling} = encode_retain_handling(retain_handling)
    {:ok, qos} = encode_qos(qos)

    encoded_data = <<
      byte_size(topic_filter)::16,
      topic_filter::binary,
      0::2,
      retain_handling::2,
      encode_boolean(rap)::1,
      encode_boolean(nl)::1,
      qos::2
    >>

    encode_topic_filters(list, data <> encoded_data)
  end

  defp encode_retain_handling(retain_handling) do
    case retain_handling do
      :send_when_subscribed -> {:ok, 0}
      :send_if_no_subscription -> {:ok, 1}
      :dont_send -> {:ok, 2}
      _ -> {:error, :protocol_error}
    end
  end

  defp encode_qos(integer) do
    case integer do
      :at_most_once -> {:ok, 0}
      :at_least_once -> {:ok, 1}
      :exactly_once -> {:ok, 2}
      _ -> {:error, :malformed_packet}
    end
  end

  defp encode_properties(_, []), do: {:ok, <<>>}

  defp encode_properties(code, properties) do
    encode_properties(code, properties, <<>>)
  end

  defp encode_properties(code, [{:payload_format_indicator, byte} | list], data)
       when code in [@publish, :will] do
    data = data <> <<@payload_format_indicator, byte>>
    encode_properties(code, list, data)
  end

  defp encode_properties(code, [{:message_expiry_interval, four_byte} | list], data)
       when code in [@publish, :will] do
    data = data <> <<@message_expiry_interval, four_byte::32>>
    encode_properties(code, list, data)
  end

  defp encode_properties(code, [{:content_type, string} | list], data)
       when code in [@publish, :will] do
    data = data <> <<@content_type, byte_size(string)::16, string::binary>>
    encode_properties(code, list, data)
  end

  defp encode_properties(code, [{:response_topic, string} | list], data)
       when code in [@publish, :will] do
    data = data <> <<@response_topic, byte_size(string)::16, string::binary>>
    encode_properties(code, list, data)
  end

  defp encode_properties(code, [{:correlation_data, string} | list], data) do
    data = data <> <<@correlation_data, byte_size(string)::16, string::binary>>
    encode_properties(code, list, data)
  end

  defp encode_properties(code, [{:subscription_identifier, vbi} | list], data)
       when code in [@publish, @subscribe] do
    {:ok, vbi} = encode_vbi(vbi)
    data = data <> <<@subscription_identifier, vbi::binary>>
    encode_properties(code, list, data)
  end

  defp encode_properties(code, [{:session_expiry_interval, four_byte} | list], data)
       when code in [@connect, @connack, @disconnect] do
    data = data <> <<@session_expiry_interval, four_byte::32>>
    encode_properties(code, list, data)
  end

  defp encode_properties(code, [{:assigned_client_identifier, string} | list], data)
       when code in [@connack] do
    data = data <> <<@assigned_client_identifier, byte_size(string)::16, string::binary>>
    encode_properties(code, list, data)
  end

  defp encode_properties(code, [{:server_keep_alive, two_byte} | list], data)
       when code in [@connack] do
    data = data <> <<@server_keep_alive, two_byte::16>>
    encode_properties(code, list, data)
  end

  defp encode_properties(code, [{:authentication_method, string} | list], data)
       when code in [@connect, @connack, @auth] do
    data = data <> <<@authentication_method, byte_size(string)::16, string::binary>>
    encode_properties(code, list, data)
  end

  defp encode_properties(code, [{:authentication_data, string} | list], data)
       when code in [@connect, @connack, @auth] do
    data = data <> <<@authentication_data, byte_size(string)::16, string::binary>>
    encode_properties(code, list, data)
  end

  defp encode_properties(code, [{:request_problem_information, byte} | list], data)
       when code in [@connect] do
    data = data <> <<@request_problem_information, byte>>
    encode_properties(code, list, data)
  end

  defp encode_properties(code, [{:will_delay_interval, four_byte} | list], data)
       when code in [:will] do
    data = data <> <<@will_delay_interval, four_byte::32>>
    encode_properties(code, list, data)
  end

  defp encode_properties(code, [{:request_response_information, byte} | list], data)
       when code in [@connect] do
    data = data <> <<@request_response_information, byte>>
    encode_properties(code, list, data)
  end

  defp encode_properties(code, [{:response_information, string} | list], data)
       when code in [@connack] do
    data = data <> <<@response_information, byte_size(string)::16, string::binary>>
    encode_properties(code, list, data)
  end

  defp encode_properties(code, [{:server_reference, string} | list], data)
       when code in [@connack, @disconnect] do
    data = data <> <<@server_reference, byte_size(string)::16, string::binary>>
    encode_properties(code, list, data)
  end

  defp encode_properties(code, [{:reason_string, string} | list], data)
       when code not in [@connect, @pingreq, @pingresp, @unsubscribe, :will] do
    data = data <> <<@reason_string, byte_size(string)::16, string::binary>>
    encode_properties(code, list, data)
  end

  defp encode_properties(code, [{:receive_maximum, two_byte} | list], data)
       when code in [@connect, @connack] do
    data = data <> <<@receive_maximum, two_byte::16>>
    encode_properties(code, list, data)
  end

  defp encode_properties(code, [{:topic_alias_maximum, two_byte} | list], data)
       when code in [@connect, @connack] do
    data = data <> <<@topic_alias_maximum, two_byte::16>>
    encode_properties(code, list, data)
  end

  defp encode_properties(code, [{:topic_alias, two_byte} | list], data)
       when code in [@publish] do
    data = data <> <<@topic_alias, two_byte::16>>
    encode_properties(code, list, data)
  end

  defp encode_properties(code, [{:maximum_qos, byte} | list], data)
       when code in [@connack] do
    data = data <> <<@maximum_qos, byte>>
    encode_properties(code, list, data)
  end

  defp encode_properties(code, [{:retain_available, byte} | list], data)
       when code in [@connack] do
    data = data <> <<@retain_available, byte>>
    encode_properties(code, list, data)
  end

  defp encode_properties(code, [{:user_property, {key, value}} | list], data) do
    data =
      data <>
        <<
          @user_property,
          byte_size(key)::16,
          key::binary,
          byte_size(value)::16,
          value::binary
        >>

    encode_properties(code, list, data)
  end

  defp encode_properties(code, [{:maximum_packet_size, four_byte} | list], data)
       when code in [@connect, @connack] do
    data = data <> <<@maximum_packet_size, four_byte::32>>
    encode_properties(code, list, data)
  end

  defp encode_properties(code, [{:wildcard_subscription_available, byte} | list], data)
       when code in [@connack] do
    data = data <> <<@wildcard_subscription_available, byte>>
    encode_properties(code, list, data)
  end

  defp encode_properties(code, [{:subscription_identifier_available, byte} | list], data)
       when code in [@connack] do
    data = data <> <<@subscription_identifier_available, byte>>
    encode_properties(code, list, data)
  end

  defp encode_properties(code, [{:shared_subscription_available, byte} | list], data)
       when code in [@connack] do
    data = data <> <<@shared_subscription_available, byte>>
    encode_properties(code, list, data)
  end

  defp encode_properties(_, [], data), do: {:ok, data}

  defp encode_properties(_, _, _), do: {:error, :malformed_packet}

  defp decode_reason_codes(_, <<>>, list), do: {:ok, Enum.reverse(list)}

  defp decode_reason_codes(code, <<data::binary>>, list) do
    <<reason_code, rest::binary>> = data
    {:ok, reason_code} = decode_reason_code(code, reason_code)
    decode_reason_codes(code, rest, [reason_code | list])
  end

  defp decode_topic_filters(<<>>, list), do: {:ok, Enum.reverse(list)}

  defp decode_topic_filters(<<data::binary>>, list) do
    <<
      length::16,
      topic_filter::binary-size(length),
      0::2,
      retain_handling::2,
      rap::1,
      nl::1,
      qos::2,
      rest::binary
    >> = data

    {:ok, retain_handling} = decode_retain_handling(retain_handling)
    {:ok, qos} = decode_qos(qos)

    decode_topic_filters(rest, [
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

  defp decode_retain_handling(integer) do
    case integer do
      0 -> {:ok, :send_when_subscribed}
      1 -> {:ok, :send_if_no_subscription}
      2 -> {:ok, :dont_send}
      _ -> {:error, :protocol_error}
    end
  end

  defp decode_vbi(data) do
    decode_vbi(data, 1, 0)
  end

  defp decode_vbi(<<1::1, num::7, rest::binary>>, multiplier, total) do
    decode_vbi(rest, multiplier <<< 7, total + num * multiplier)
  end

  defp decode_vbi(<<0::1, num::7, _::binary>>, multiplier, total) do
    {:ok, total + num * multiplier}
  end

  defp decode_vbi(_, _, _), do: {:error, :malformed_packet}

  defp vbi_size(<<0::1, _::7, _::binary>>), do: 1
  defp vbi_size(<<1::1, _::7, 0::1, _::7, _::binary>>), do: 2
  defp vbi_size(<<1::1, _::7, 1::1, _::7, 0::1, _::7, _::binary>>), do: 3
  defp vbi_size(<<1::1, _::7, 1::1, _::7, 1::1, _::7, 0::1, _::7, _::binary>>), do: 4

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
      0 -> {:ok, :at_most_once}
      1 -> {:ok, :at_least_once}
      2 -> {:ok, :exactly_once}
      _ -> {:error, :malformed_packet}
    end
  end

  defp decode_properties(_, <<>>), do: {:ok, nil}

  defp decode_properties(code, <<data::binary>>) do
    decode_properties(code, data, [])
  end

  defp decode_properties(code, <<@payload_format_indicator, rest::binary>>, list)
       when code in [@publish, :will] do
    <<byte, rest::binary>> = rest
    decode_properties(code, rest, [{:payload_format_indicator, byte} | list])
  end

  defp decode_properties(code, <<@message_expiry_interval, rest::binary>>, list)
       when code in [@publish, :will] do
    <<four_byte::32, rest::binary>> = rest
    decode_properties(code, rest, [{:message_expiry_interval, four_byte} | list])
  end

  defp decode_properties(code, <<@content_type, rest::binary>>, list)
       when code in [@publish, :will] do
    <<length::16, string::binary-size(length), rest::binary>> = rest
    decode_properties(code, rest, [{:content_type, string} | list])
  end

  defp decode_properties(code, <<@response_topic, rest::binary>>, list)
       when code in [@publish, :will] do
    <<length::16, string::binary-size(length), rest::binary>> = rest
    decode_properties(code, rest, [{:response_topic, string} | list])
  end

  defp decode_properties(code, <<@correlation_data, rest::binary>>, list)
       when code in [@publish, :will] do
    <<length::16, string::binary-size(length), rest::binary>> = rest
    decode_properties(code, rest, [{:correlation_data, string} | list])
  end

  defp decode_properties(code, <<@subscription_identifier, rest::binary>>, list)
       when code in [@publish, @subscribe] do
    {:ok, vbi} = decode_vbi(rest)
    size = vbi_size(rest)
    <<_::size(size), rest::binary>> = rest
    decode_properties(code, rest, [{:subscription_identifier, vbi} | list])
  end

  defp decode_properties(code, <<@session_expiry_interval, rest::binary>>, list)
       when code in [@connect, @connack, @disconnect] do
    <<four_byte::32, rest::binary>> = rest
    decode_properties(code, rest, [{:session_expiry_interval, four_byte} | list])
  end

  defp decode_properties(code, <<@assigned_client_identifier, rest::binary>>, list)
       when code in [@connack] do
    <<length::16, string::binary-size(length), rest::binary>> = rest
    decode_properties(code, rest, [{:assigned_client_identifier, string} | list])
  end

  defp decode_properties(code, <<@server_keep_alive, rest::binary>>, list)
       when code in [@connack] do
    <<two_byte::16, rest::binary>> = rest
    decode_properties(code, rest, [{:server_keep_alive, two_byte} | list])
  end

  defp decode_properties(code, <<@authentication_method, rest::binary>>, list)
       when code in [@connect, @connack, @auth] do
    <<length::16, string::binary-size(length), rest::binary>> = rest
    decode_properties(code, rest, [{:authentication_method, string} | list])
  end

  defp decode_properties(code, <<@authentication_data, rest::binary>>, list)
       when code in [@connect, @connack, @auth] do
    <<length::16, string::binary-size(length), rest::binary>> = rest
    decode_properties(code, rest, [{:authentication_data, string} | list])
  end

  defp decode_properties(code, <<@request_problem_information, rest::binary>>, list)
       when code in [@connect] do
    <<byte, rest::binary>> = rest
    decode_properties(code, rest, [{:request_problem_information, byte} | list])
  end

  defp decode_properties(code, <<@will_delay_interval, rest::binary>>, list)
       when code in [:will] do
    <<four_byte::32, rest::binary>> = rest
    decode_properties(code, rest, [{:will_delay_interval, four_byte} | list])
  end

  defp decode_properties(code, <<@request_response_information, rest::binary>>, list)
       when code in [@connect] do
    <<byte, rest::binary>> = rest
    decode_properties(code, rest, [{:request_response_information, byte} | list])
  end

  defp decode_properties(code, <<@response_information, rest::binary>>, list)
       when code in [@connack] do
    <<length::16, string::binary-size(length), rest::binary>> = rest
    decode_properties(code, rest, [{:response_information, string} | list])
  end

  defp decode_properties(code, <<@server_reference, rest::binary>>, list)
       when code in [@connack, @disconnect] do
    <<length::16, string::binary-size(length), rest::binary>> = rest
    decode_properties(code, rest, [{:server_reference, string} | list])
  end

  defp decode_properties(code, <<@reason_string, rest::binary>>, list)
       when code not in [@connect, @pingreq, @pingresp, @unsubscribe, :will] do
    <<length::16, string::binary-size(length), rest::binary>> = rest
    decode_properties(code, rest, [{:reason_string, string} | list])
  end

  defp decode_properties(code, <<@receive_maximum, rest::binary>>, list)
       when code in [@connect, @connack] do
    <<two_byte::16, rest::binary>> = rest
    decode_properties(code, rest, [{:receive_maximum, two_byte} | list])
  end

  defp decode_properties(code, <<@topic_alias_maximum, rest::binary>>, list)
       when code in [@connect, @connack] do
    <<two_byte::16, rest::binary>> = rest
    decode_properties(code, rest, [{:topic_alias_maximum, two_byte} | list])
  end

  defp decode_properties(code, <<@topic_alias, rest::binary>>, list)
       when code in [@publish] do
    <<two_byte::16, rest::binary>> = rest
    decode_properties(code, rest, [{:topic_alias, two_byte} | list])
  end

  defp decode_properties(code, <<@maximum_qos, rest::binary>>, list)
       when code in [@connack] do
    <<byte, rest::binary>> = rest
    decode_properties(code, rest, [{:maximum_qos, byte} | list])
  end

  defp decode_properties(code, <<@retain_available, rest::binary>>, list)
       when code in [@connack] do
    <<byte, rest::binary>> = rest
    decode_properties(code, rest, [{:retain_available, byte} | list])
  end

  defp decode_properties(code, <<@user_property, rest::binary>>, list) do
    <<
      key_length::16,
      key::size(key_length),
      value_length::16,
      value::size(value_length),
      rest::binary
    >> = rest

    decode_properties(code, rest, [{:user_property, {key, value}} | list])
  end

  defp decode_properties(code, <<@maximum_packet_size, rest::binary>>, list)
       when code in [@connect, @connack] do
    <<four_byte::32, rest::binary>> = rest
    decode_properties(code, rest, [{:maximum_packet_size, four_byte} | list])
  end

  defp decode_properties(code, <<@wildcard_subscription_available, rest::binary>>, list)
       when code in [@connack] do
    <<byte, rest::binary>> = rest
    decode_properties(code, rest, [{:wildcard_subscription_available, byte} | list])
  end

  defp decode_properties(code, <<@subscription_identifier_available, rest::binary>>, list)
       when code in [@connack] do
    <<byte, rest::binary>> = rest
    decode_properties(code, rest, [{:subscription_identifier_available, byte} | list])
  end

  defp decode_properties(code, <<@shared_subscription_available, rest::binary>>, list)
       when code in [@connack] do
    <<byte, rest::binary>> = rest
    decode_properties(code, rest, [{:shared_subscription_available, byte} | list])
  end

  defp decode_properties(_, <<>>, list), do: {:ok, list}

  defp decode_properties(_, _, _), do: {:error, :malformed_packet}
end
