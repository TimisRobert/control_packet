defmodule StarflareMqtt.Packet.Connect do
  @moduledoc false

  alias StarflareMqtt.Packet.Type.{
    TwoByte,
    Qos,
    Boolean,
    Binary,
    Utf8,
    Property
  }

  @protocol_name_len 4
  @protocol_version 5
  @header <<@protocol_name_len::16, "MQTT", @protocol_version>>

  defstruct [
    :clientid,
    :properties,
    :clean_start,
    :will,
    :username,
    :password,
    :keep_alive,
    will_retain: false,
    will_qos: :at_most_once
  ]

  def decode(<<@header, rest::binary>>) do
    with {:ok,
          {
            username_flag,
            password_flag,
            will_retain,
            will_qos,
            will_flag,
            clean_start
          }, rest} <- decode_flags(rest),
         {:ok, keep_alive, rest} <- TwoByte.decode(rest),
         {:ok, properties, rest} <- Property.decode(rest),
         {:ok, clientid, rest} <- Utf8.decode(rest),
         {:ok, will, rest} <- decode_will(will_flag, rest),
         {:ok, username, rest} <- decode_string(username_flag, rest),
         {:ok, password, _} <- decode_string(password_flag, rest) do
      {:ok,
       %__MODULE__{
         clientid: clientid,
         properties: properties,
         will: will,
         will_qos: will_qos,
         will_retain: will_retain,
         keep_alive: keep_alive,
         username: username,
         password: password,
         clean_start: clean_start
       }}
    end
  end

  def decode(_), do: {:error, :unsupported_protocol_error}

  defp decode_string(true, data), do: Utf8.decode(data)
  defp decode_string(false, data), do: {:ok, nil, data}

  defp decode_will(false, data), do: {:ok, nil, data}

  defp decode_will(true, data) do
    with {:ok, properties, rest} <- Property.decode(data),
         {:ok, topic, rest} <- Utf8.decode(rest),
         {:ok, payload, rest} <- Binary.decode(rest) do
      {:ok, [properties: properties, topic: topic, payload: payload], rest}
    end
  end

  defp decode_flags(data) do
    with {:ok, username_flag, rest} <- Boolean.decode(data),
         {:ok, password_flag, rest} <- Boolean.decode(rest),
         {:ok, will_retain, rest} <- Boolean.decode(rest),
         {:ok, will_qos, rest} <- Qos.decode(rest),
         {:ok, will_flag, rest} <- Boolean.decode(rest),
         {:ok, clean_start, rest} <- Boolean.decode(rest),
         {:ok, false, rest} <- Boolean.decode(rest) do
      {:ok,
       {
         username_flag,
         password_flag,
         will_retain,
         will_qos,
         will_flag,
         clean_start
       }, rest}
    end
  end

  def encode(%__MODULE__{} = packet) do
    %__MODULE__{
      password: password,
      username: username,
      clientid: clientid,
      properties: properties,
      keep_alive: keep_alive,
      will: will
    } = packet

    with {:ok, data} <- Utf8.encode(password),
         encoded_data <- data,
         {:ok, data} <- Utf8.encode(username),
         encoded_data <- data <> encoded_data,
         {:ok, data} <- encode_will(will),
         encoded_data <- data <> encoded_data,
         {:ok, data} <- Utf8.encode(clientid),
         encoded_data <- data <> encoded_data,
         {:ok, data} <- Property.encode(properties),
         encoded_data <- data <> encoded_data,
         {:ok, data} <- TwoByte.encode(keep_alive),
         encoded_data <- data <> encoded_data,
         {:ok, data} <- encode_flags(packet),
         encoded_data <- @header <> data <> encoded_data do
      {:ok, encoded_data}
    end
  end

  defp encode_will(nil), do: {:ok, <<>>}

  defp encode_will(will) do
    with {:ok, data} <- Binary.encode(will.payload),
         encoded_data <- data,
         {:ok, data} <- Utf8.encode(will.topic),
         encoded_data <- data <> encoded_data,
         {:ok, data} <- Property.encode(will.properties),
         encoded_data <- data <> encoded_data do
      {:ok, encoded_data}
    end
  end

  defp encode_flags(%__MODULE__{} = packet) do
    %__MODULE__{
      password: password,
      username: username,
      will: will,
      will_qos: will_qos,
      will_retain: will_retain,
      clean_start: clean_start
    } = packet

    will_flag = !!will

    will_qos =
      if will_flag do
        will_qos
      else
        :at_most_once
      end

    will_retain =
      if will_flag do
        false
      else
        will_retain
      end

    with {:ok, will_flag} <- Boolean.encode(!!will),
         {:ok, will_qos} <- Qos.encode(will_qos),
         {:ok, will_retain} <- Boolean.encode(will_retain),
         {:ok, password_flag} <- Boolean.encode(!!password),
         {:ok, username_flag} <- Boolean.encode(!!username),
         {:ok, clean_start} <- Boolean.encode(clean_start) do
      {:ok,
       <<
         username_flag::bitstring,
         password_flag::bitstring,
         will_retain::bitstring,
         will_qos::bitstring,
         will_flag::bitstring,
         clean_start::bitstring,
         0::1
       >>}
    end
  end
end
