defmodule ControlPacket.Properties do
  @moduledoc false

  @properties [
    :payload_format_indicator,
    :message_expiry_interval,
    :content_type,
    :response_topic,
    :correlation_data,
    :subscription_identifier,
    :session_expiry_interval,
    :assigned_client_identifier,
    :server_keep_alive,
    :authentication_method,
    :authentication_data,
    :request_problem_information,
    :will_delay_interval,
    :request_response_information,
    :response_information,
    :server_reference,
    :reason_string,
    :receive_maximum,
    :topic_alias_maximum,
    :topic_alias,
    :maximum_qos,
    :retain_available,
    :maximum_packet_size,
    :wildcard_subscription_available,
    :subscription_identifier_available,
    :shared_subscription_available
  ]

  def new(properties) do
    {user_property, properties} = Keyword.pop_values(properties, :user_property)

    case Keyword.validate(properties, @properties) do
      {:ok, properties} ->
        properties =
          Enum.reduce(user_property, properties, &Keyword.put(&2, :user_property, &1))

        {:ok, properties}

      {:error, _} ->
        {:error, :malformed_packet}
    end
  end
end
