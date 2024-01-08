defmodule StarflareMqtt.Packet.Type.ReasonCode do
  @moduledoc false

  alias StarflareMqtt.Packet.{
    Auth,
    Connack,
    Disconnect,
    Puback,
    Pubcomp,
    Pubrec,
    Pubrel,
    Suback,
    Unsuback
  }

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

  def decode(module, <<@success, rest::binary>>)
      when module in [Connack, Puback, Pubrec, Pubrel, Pubcomp, Unsuback, Auth],
      do: {:ok, :success, rest}

  def decode(module, <<@normal_disconnection, rest::binary>>)
      when module in [Disconnect],
      do: {:ok, :normal_disconnection, rest}

  def decode(module, <<@granted_qos_0, rest::binary>>)
      when module in [Suback],
      do: {:ok, :granted_qos_0, rest}

  def decode(module, <<@granted_qos_1, rest::binary>>)
      when module in [Suback],
      do: {:ok, :granted_qos_1, rest}

  def decode(module, <<@granted_qos_2, rest::binary>>)
      when module in [Suback],
      do: {:ok, :granted_qos_2, rest}

  def decode(module, <<@disconnect_with_will_message, rest::binary>>)
      when module in [Disconnect],
      do: {:ok, :disconnect_with_will_message, rest}

  def decode(module, <<@no_matching_subscribers, rest::binary>>)
      when module in [Puback, Pubrec],
      do: {:ok, :no_matching_subscribers, rest}

  def decode(module, <<@no_subscription_existed, rest::binary>>)
      when module in [Unsuback],
      do: {:ok, :no_subscription_existed, rest}

  def decode(module, <<@continue_authentication, rest::binary>>)
      when module in [Auth],
      do: {:ok, :continue_authentication, rest}

  def decode(module, <<@re_authenticate, rest::binary>>)
      when module in [Auth],
      do: {:ok, :re_authenticate, rest}

  def decode(module, <<@unspecified_error, rest::binary>>)
      when module in [Connack, Puback, Pubrec, Suback, Unsuback, Disconnect],
      do: {:ok, :unspecified_error, rest}

  def decode(module, <<@malformed_packet, rest::binary>>)
      when module in [Connack, Disconnect],
      do: {:ok, :malformed_packet, rest}

  def decode(module, <<@protocol_error, rest::binary>>)
      when module in [Connack, Disconnect],
      do: {:ok, :protocol_error, rest}

  def decode(module, <<@implementation_specific_error, rest::binary>>)
      when module in [Connack, Puback, Pubrec, Suback, Unsuback, Disconnect],
      do: {:ok, :implementation_specific_error, rest}

  def decode(module, <<@unsupported_protocol_error, rest::binary>>)
      when module in [Connack],
      do: {:ok, :unsupported_protocol_error, rest}

  def decode(module, <<@client_identifier_not_valid, rest::binary>>)
      when module in [Connack],
      do: {:ok, :client_identifier_not_valid, rest}

  def decode(module, <<@bad_username_or_password, rest::binary>>)
      when module in [Connack],
      do: {:ok, :bad_username_or_password, rest}

  def decode(module, <<@not_authorized, rest::binary>>)
      when module in [Connack, Puback, Pubrec, Suback, Unsuback, Disconnect],
      do: {:ok, :not_authorized, rest}

  def decode(module, <<@server_unavailable, rest::binary>>)
      when module in [Connack],
      do: {:ok, :server_unavailable, rest}

  def decode(module, <<@server_busy, rest::binary>>)
      when module in [Connack, Disconnect],
      do: {:ok, :server_busy, rest}

  def decode(module, <<@banned, rest::binary>>)
      when module in [Connack],
      do: {:ok, :banned, rest}

  def decode(module, <<@server_shutting_down, rest::binary>>)
      when module in [Disconnect],
      do: {:ok, :server_shutting_down, rest}

  def decode(module, <<@bad_authentication_method, rest::binary>>)
      when module in [Connack, Disconnect],
      do: {:ok, :bad_authentication_method, rest}

  def decode(module, <<@keep_alive_timeout, rest::binary>>)
      when module in [Disconnect],
      do: {:ok, :keep_alive_timeout, rest}

  def decode(module, <<@session_taken_over, rest::binary>>)
      when module in [Disconnect],
      do: {:ok, :session_taken_over, rest}

  def decode(module, <<@topic_filter_invalid, rest::binary>>)
      when module in [Suback, Unsuback, Disconnect],
      do: {:ok, :topic_filter_invalid, rest}

  def decode(module, <<@topic_name_invalid, rest::binary>>)
      when module in [Connack, Puback, Pubrec, Disconnect],
      do: {:ok, :topic_name_invalid, rest}

  def decode(module, <<@packet_identifier_in_use, rest::binary>>)
      when module in [Puback, Pubrec, Suback, Unsuback],
      do: {:ok, :packet_identifier_in_use, rest}

  def decode(module, <<@packet_identifier_not_found, rest::binary>>)
      when module in [Pubrel, Pubcomp],
      do: {:ok, :packet_identifier_not_found, rest}

  def decode(module, <<@receive_maximum_exceeded, rest::binary>>)
      when module in [Disconnect],
      do: {:ok, :receive_maximum_exceeded, rest}

  def decode(module, <<@topic_alias_invalid, rest::binary>>)
      when module in [Disconnect],
      do: {:ok, :topic_alias_invalid, rest}

  def decode(module, <<@packet_too_large, rest::binary>>)
      when module in [Connack, Disconnect],
      do: {:ok, :packet_too_large, rest}

  def decode(module, <<@message_rate_too_high, rest::binary>>)
      when module in [Disconnect],
      do: {:ok, :message_rate_too_high, rest}

  def decode(module, <<@quota_exceeded, rest::binary>>)
      when module in [Connack, Puback, Pubrec, Suback, Disconnect],
      do: {:ok, :quota_exceeded, rest}

  def decode(module, <<@administrative_action, rest::binary>>)
      when module in [Disconnect],
      do: {:ok, :administrative_action, rest}

  def decode(module, <<@payload_format_invalid, rest::binary>>)
      when module in [Connack, Puback, Pubrec, Disconnect],
      do: {:ok, :payload_format_invalid, rest}

  def decode(module, <<@retain_not_supported, rest::binary>>)
      when module in [Connack, Disconnect],
      do: {:ok, :retain_not_supported, rest}

  def decode(module, <<@qos_not_supported, rest::binary>>)
      when module in [Connack, Disconnect],
      do: {:ok, :qos_not_supported, rest}

  def decode(module, <<@use_another_server, rest::binary>>)
      when module in [Connack, Disconnect],
      do: {:ok, :use_another_server, rest}

  def decode(module, <<@server_moved, rest::binary>>)
      when module in [Connack, Disconnect],
      do: {:ok, :server_moved, rest}

  def decode(module, <<@shared_subscriptions_not_supported, rest::binary>>)
      when module in [Suback, Disconnect],
      do: {:ok, :shared_subscriptions_not_supported, rest}

  def decode(module, <<@connection_rate_exceeded, rest::binary>>)
      when module in [Connack, Disconnect],
      do: {:ok, :connection_rate_exceeded, rest}

  def decode(module, <<@maximum_connect_time, rest::binary>>)
      when module in [Disconnect],
      do: {:ok, :maximum_connect_time, rest}

  def decode(module, <<@subscription_identifiers_not_supported, rest::binary>>)
      when module in [Suback, Disconnect],
      do: {:ok, :subscription_identifiers_not_supported, rest}

  def decode(module, <<@wildcard_subscriptions_not_supported, rest::binary>>)
      when module in [Suback, Disconnect],
      do: {:ok, :wildcard_subscriptions_not_supported, rest}

  def decode(_, _), do: {:error, :protocol_error}

  def encode(module, :success)
      when module in [Connack, Puback, Pubrec, Pubrel, Pubcomp, Unsuback, Auth],
      do: {:ok, <<@success>>}

  def encode(module, :normal_disconnection)
      when module in [Disconnect],
      do: {:ok, <<@normal_disconnection>>}

  def encode(module, :granted_qos_0)
      when module in [Suback],
      do: {:ok, <<@granted_qos_0>>}

  def encode(module, :granted_qos_1)
      when module in [Suback],
      do: {:ok, <<@granted_qos_1>>}

  def encode(module, :granted_qos_2)
      when module in [Suback],
      do: {:ok, <<@granted_qos_2>>}

  def encode(module, :disconnect_with_will_message)
      when module in [Disconnect],
      do: {:ok, <<@disconnect_with_will_message>>}

  def encode(module, :no_matching_subscribers)
      when module in [Puback, Pubrec],
      do: {:ok, <<@no_matching_subscribers>>}

  def encode(module, :no_subscription_existed)
      when module in [Unsuback],
      do: {:ok, <<@no_subscription_existed>>}

  def encode(module, :continue_authentication)
      when module in [Auth],
      do: {:ok, <<@continue_authentication>>}

  def encode(module, :re_authenticate)
      when module in [Auth],
      do: {:ok, <<@re_authenticate>>}

  def encode(module, :unspecified_error)
      when module in [Connack, Puback, Pubrec, Suback, Unsuback, Disconnect],
      do: {:ok, <<@unspecified_error>>}

  def encode(module, :malformed_packet)
      when module in [Connack, Disconnect],
      do: {:ok, <<@malformed_packet>>}

  def encode(module, :protocol_error)
      when module in [Connack, Disconnect],
      do: {:ok, <<@protocol_error>>}

  def encode(module, :implementation_specific_error)
      when module in [Connack, Puback, Pubrec, Suback, Unsuback, Disconnect],
      do: {:ok, <<@implementation_specific_error>>}

  def encode(module, :unsupported_protocol_error)
      when module in [Connack],
      do: {:ok, <<@unsupported_protocol_error>>}

  def encode(module, :client_identifier_not_valid)
      when module in [Connack],
      do: {:ok, <<@client_identifier_not_valid>>}

  def encode(module, :bad_username_or_password)
      when module in [Connack],
      do: {:ok, <<@bad_username_or_password>>}

  def encode(module, :not_authorized)
      when module in [Connack, Puback, Pubrec, Suback, Unsuback, Disconnect],
      do: {:ok, <<@not_authorized>>}

  def encode(module, :server_unavailable)
      when module in [Connack],
      do: {:ok, <<@server_unavailable>>}

  def encode(module, :server_busy)
      when module in [Connack, Disconnect],
      do: {:ok, <<@server_busy>>}

  def encode(module, :banned)
      when module in [Connack],
      do: {:ok, <<@banned>>}

  def encode(module, :server_shutting_down)
      when module in [Disconnect],
      do: {:ok, <<@server_shutting_down>>}

  def encode(module, :bad_authentication_method)
      when module in [Connack, Disconnect],
      do: {:ok, <<@bad_authentication_method>>}

  def encode(module, :keep_alive_timeout)
      when module in [Disconnect],
      do: {:ok, <<@keep_alive_timeout>>}

  def encode(module, :session_taken_over)
      when module in [Disconnect],
      do: {:ok, <<@session_taken_over>>}

  def encode(module, :topic_filter_invalid)
      when module in [Suback, Unsuback, Disconnect],
      do: {:ok, <<@topic_filter_invalid>>}

  def encode(module, :topic_name_invalid)
      when module in [Connack, Puback, Pubrec, Disconnect],
      do: {:ok, <<@topic_name_invalid>>}

  def encode(module, :packet_identifier_in_use)
      when module in [Puback, Pubrec, Suback, Unsuback],
      do: {:ok, <<@packet_identifier_in_use>>}

  def encode(module, :packet_identifier_not_found)
      when module in [Pubrel, Pubcomp],
      do: {:ok, <<@packet_identifier_not_found>>}

  def encode(module, :receive_maximum_exceeded)
      when module in [Disconnect],
      do: {:ok, <<@receive_maximum_exceeded>>}

  def encode(module, :topic_alias_invalid)
      when module in [Disconnect],
      do: {:ok, <<@topic_alias_invalid>>}

  def encode(module, :packet_too_large)
      when module in [Connack, Disconnect],
      do: {:ok, <<@packet_too_large>>}

  def encode(module, :message_rate_too_high)
      when module in [Disconnect],
      do: {:ok, <<@message_rate_too_high>>}

  def encode(module, :quota_exceeded)
      when module in [Connack, Puback, Pubrec, Suback, Disconnect],
      do: {:ok, <<@quota_exceeded>>}

  def encode(module, :administrative_action)
      when module in [Disconnect],
      do: {:ok, <<@administrative_action>>}

  def encode(module, :payload_format_invalid)
      when module in [Connack, Puback, Pubrec, Disconnect],
      do: {:ok, <<@payload_format_invalid>>}

  def encode(module, :retain_not_supported)
      when module in [Connack, Disconnect],
      do: {:ok, <<@retain_not_supported>>}

  def encode(module, :qos_not_supported)
      when module in [Connack, Disconnect],
      do: {:ok, <<@qos_not_supported>>}

  def encode(module, :use_another_server)
      when module in [Connack, Disconnect],
      do: {:ok, <<@use_another_server>>}

  def encode(module, :server_moved)
      when module in [Connack, Disconnect],
      do: {:ok, <<@server_moved>>}

  def encode(module, :shared_subscriptions_not_supported)
      when module in [Suback, Disconnect],
      do: {:ok, <<@shared_subscriptions_not_supported>>}

  def encode(module, :connection_rate_exceeded)
      when module in [Connack, Disconnect],
      do: {:ok, <<@connection_rate_exceeded>>}

  def encode(module, :maximum_connect_time)
      when module in [Disconnect],
      do: {:ok, <<@maximum_connect_time>>}

  def encode(module, :subscription_identifiers_not_supported)
      when module in [Suback, Disconnect],
      do: {:ok, <<@subscription_identifiers_not_supported>>}

  def encode(module, :wildcard_subscriptions_not_supported)
      when module in [Suback, Disconnect],
      do: {:ok, <<@wildcard_subscriptions_not_supported>>}

  def encode(_, _), do: {:error, :protocol_error}
end
