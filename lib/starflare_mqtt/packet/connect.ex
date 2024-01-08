defmodule StarflareMqtt.Packet.Connect do
  @moduledoc """
  Connect packet
  """

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
    :will_retain,
    :will_qos,
    :clean_start,
    :will,
    :username,
    :password,
    :keep_alive
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

  def decode(_), do: {:error, :decode_error}

  def encode(%__MODULE__{} = packet) do
    %__MODULE__{
      password: password,
      username: username,
      clientid: clientid,
      properties: properties,
      keep_alive: keep_alive,
      will: will
    } = packet

    with {:ok, data} <- encode_string(password),
         encoded_data <- <<data::binary>>,
         {:ok, data} <- encode_string(username),
         encoded_data <- <<data::binary>> <> encoded_data,
         {:ok, data} <- encode_will(will),
         encoded_data <- <<data::binary>> <> encoded_data,
         {:ok, data} <- Utf8.encode(clientid),
         encoded_data <- <<data::binary>> <> encoded_data,
         {:ok, data} <- Property.encode(properties),
         encoded_data <- <<data::binary>> <> encoded_data,
         {:ok, data} <- TwoByte.encode(keep_alive),
         encoded_data <- <<data::binary>> <> encoded_data,
         {:ok, data} <- encode_flags(packet),
         encoded_data <- <<data::binary>> <> encoded_data,
         encoded_data <- @header <> encoded_data do
      {:ok, encoded_data}
    end
  end

  defp encode_will(nil), do: {:ok, <<>>}

  defp encode_will(will) do
    with {:ok, data} <- Binary.encode(will.payload),
         encoded_data <- <<data::binary>>,
         {:ok, data} <- Utf8.encode(will.topic),
         encoded_data <- <<data::binary>> <> encoded_data,
         {:ok, data} <- Property.encode(will.properties),
         encoded_data <- <<data::binary>> <> encoded_data do
      {:ok, encoded_data}
    end
  end

  defp encode_string(nil), do: {:ok, <<0::16>>}
  defp encode_string(string), do: Utf8.encode(string)

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

  defp decode_flags(<<
         username_flag::1,
         password_flag::1,
         will_retain::1,
         will_qos::2,
         will_flag::1,
         clean_start::1,
         _reserved::1,
         rest::binary
       >>) do
    with {:ok, username_flag} <- Boolean.decode(username_flag),
         {:ok, password_flag} <- Boolean.decode(password_flag),
         {:ok, will_retain} <- Boolean.decode(will_retain),
         {:ok, will_qos} <- Qos.decode(will_qos),
         {:ok, will_flag} <- Boolean.decode(will_flag),
         {:ok, clean_start} <- Boolean.decode(clean_start) do
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

  defp encode_flags(%__MODULE__{} = packet) do
    %__MODULE__{
      password: password,
      username: username,
      will: will,
      will_qos: will_qos,
      will_retain: will_retain,
      clean_start: clean_start
    } = packet

    with {:ok, will_flag} <- Boolean.encode(!!will),
         {:ok, will_qos} <- Qos.encode(will_qos),
         {:ok, will_retain} <- Boolean.encode(will_retain),
         {:ok, password_flag} <- Boolean.encode(!!password),
         {:ok, username_flag} <- Boolean.encode(!!username),
         {:ok, clean_start} <- Boolean.encode(clean_start) do
      {:ok,
       <<
         username_flag::1,
         password_flag::1,
         will_retain::1,
         will_qos::2,
         will_flag::1,
         clean_start::1,
         0::1
       >>}
    end
  end
end
