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

  @success {0x00, :success, [Connack, Puback, Pubrec, Pubrel, Pubcomp, Unsuback, Auth]}
  @normal_disconnection {0x00, :normal_disconnection, [Disconnect]}
  @granted_qos_0 {0x00, :granted_qos_0, [Suback]}
  @granted_qos_1 {0x01, :granted_qos_1, [Suback]}
  @granted_qos_2 {0x02, :granted_qos_2, [Suback]}
  @disconnect_with_will_message {0x04, :disconnect_with_will_message, [Disconnect]}
  @no_matching_subscribers {0x10, :no_matching_subscribers, [Puback, Pubrec]}
  @no_subscription_existed {0x11, :no_subscription_existed, [Unsuback]}
  @continue_authentication {0x18, :continue_authentication, [Auth]}
  @re_authenticate {0x19, :re_authenticate, [Auth]}
  @unspecified_error {0x80, :unspecified_error,
                      [Connack, Puback, Pubrec, Suback, Unsuback, Disconnect]}
  @malformed_packet {0x81, :malformed_packet, [Connack, Disconnect]}
  @protocol_error {0x82, :protocol_error, [Connack, Disconnect]}
  @implementation_specific_error {0x83, :implementation_specific_error,
                                  [Connack, Puback, Pubrec, Suback, Unsuback, Disconnect]}
  @unsupported_protocol_error {0x84, :unsupported_protocol_error, [Connack]}
  @client_identifier_not_valid {0x85, :client_identifier_not_valid, [Connack]}
  @bad_username_or_password {0x86, :bad_username_or_password, [Connack]}
  @not_authorized {0x87, :not_authorized, [Connack, Puback, Pubrec, Suback, Unsuback, Disconnect]}
  @server_unavailable {0x88, :server_unavailable, [Connack]}
  @server_busy {0x89, :server_busy, [Connack, Disconnect]}
  @banned {0x8A, :banned, [Connack]}
  @server_shutting_down {0x8B, :server_shutting_down, [Disconnect]}
  @bad_authentication_method {0x8C, :bad_authentication_method, [Connack, Disconnect]}
  @keep_alive_timeout {0x8D, :keep_alive_timeout, [Disconnect]}
  @session_taken_over {0x8E, :session_taken_over, [Disconnect]}
  @topic_filter_invalid {0x8F, :topic_filter_invalid, [Suback, Unsuback, Disconnect]}
  @topic_name_invalid {0x90, :topic_name_invalid, [Connack, Puback, Pubrec, Disconnect]}
  @packet_identifier_in_use {0x91, :packet_identifier_in_use, [Puback, Pubrec, Suback, Unsuback]}
  @packet_identifier_not_found {0x92, :packet_identifier_not_found, [Pubrel, Pubcomp]}
  @receive_maximum_exceeded {0x93, :receive_maximum_exceeded, [Disconnect]}
  @topic_alias_invalid {0x94, :topic_alias_invalid, [Disconnect]}
  @packet_too_large {0x95, :packet_too_large, [Connack, Disconnect]}
  @message_rate_too_high {0x96, :message_rate_too_high, [Disconnect]}
  @quota_exceeded {0x97, :quota_exceeded, [Connack, Puback, Pubrec, Suback, Disconnect]}
  @administrative_action {0x98, :administrative_action, [Disconnect]}
  @payload_format_invalid {0x99, :payload_format_invalid, [Connack, Puback, Pubrec, Disconnect]}
  @retain_not_supported {0x9A, :retain_not_supported, [Connack, Disconnect]}
  @qos_not_supported {0x9B, :qos_not_supported, [Connack, Disconnect]}
  @use_another_server {0x9C, :use_another_server, [Connack, Disconnect]}
  @server_moved {0x9D, :server_moved, [Connack, Disconnect]}
  @shared_subscriptions_not_supported {0x9E, :shared_subscriptions_not_supported,
                                       [Suback, Disconnect]}
  @connection_rate_exceeded {0x9F, :connection_rate_exceeded, [Connack, Disconnect]}
  @maximum_connect_time {0xA0, :maximum_connect_time, [Disconnect]}
  @subscription_identifiers_not_supported {0xA1, :subscription_identifiers_not_supported,
                                           [Suback, Disconnect]}
  @wildcard_subscriptions_not_supported {0xA2, :wildcard_subscriptions_not_supported,
                                         [Suback, Disconnect]}

  @reason_codes [
    @success,
    @normal_disconnection,
    @granted_qos_0,
    @granted_qos_1,
    @granted_qos_2,
    @disconnect_with_will_message,
    @no_matching_subscribers,
    @no_subscription_existed,
    @continue_authentication,
    @re_authenticate,
    @unspecified_error,
    @malformed_packet,
    @protocol_error,
    @implementation_specific_error,
    @unsupported_protocol_error,
    @client_identifier_not_valid,
    @bad_username_or_password,
    @not_authorized,
    @server_unavailable,
    @server_busy,
    @banned,
    @server_shutting_down,
    @bad_authentication_method,
    @keep_alive_timeout,
    @session_taken_over,
    @topic_filter_invalid,
    @topic_name_invalid,
    @packet_identifier_in_use,
    @packet_identifier_not_found,
    @receive_maximum_exceeded,
    @topic_alias_invalid,
    @packet_too_large,
    @message_rate_too_high,
    @quota_exceeded,
    @administrative_action,
    @payload_format_invalid,
    @retain_not_supported,
    @qos_not_supported,
    @use_another_server,
    @server_moved,
    @shared_subscriptions_not_supported,
    @connection_rate_exceeded,
    @maximum_connect_time,
    @subscription_identifiers_not_supported,
    @wildcard_subscriptions_not_supported
  ]

  @reason_code_atoms Enum.map(@reason_codes, fn {_, atom, _} -> atom end)

  defguard is_reason_code(reason_code)
           when reason_code in @reason_code_atoms

  for {code, atom, guard} <- @reason_codes do
    def decode(module, <<unquote(code), rest::binary>>)
        when module in unquote(guard),
        do: {:ok, unquote(atom), rest}
  end

  def decode(_, _), do: {:error, :protocol_error}

  for {code, atom, guard} <- @reason_codes do
    def encode(module, unquote(atom))
        when module in unquote(guard),
        do: {:ok, <<unquote(code)>>}
  end

  def encode(_, _), do: {:error, :protocol_error}
end
