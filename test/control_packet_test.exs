defmodule ControlPacketTest do
  use ExUnit.Case
  doctest ControlPacket

  test "connect" do
    packet = %ControlPacket.Connect{
      username: "test",
      password: "test",
      clientid: "one"
    }

    {:ok, encoded, _size} = ControlPacket.encode(packet)

    {:ok, [decoded], _size} = ControlPacket.decode_buffer(encoded)
    assert decoded === packet

    {:ok, encoded_again, _size} = ControlPacket.encode(decoded)
    assert encoded === encoded_again
  end

  test "connack" do
    packet = %ControlPacket.Connack{}

    {:ok, encoded, _size} = ControlPacket.encode(packet)

    {:ok, [decoded], _size} = ControlPacket.decode_buffer(encoded)
    assert decoded === packet

    {:ok, encoded_again, _size} = ControlPacket.encode(decoded)
    assert encoded === encoded_again
  end

  test "publish qos0" do
    packet = %ControlPacket.Publish{
      topic_name: "test",
      payload: "test",
      qos_level: :at_most_once
    }

    {:ok, encoded, _size} = ControlPacket.encode(packet)

    {:ok, [decoded], _size} = ControlPacket.decode_buffer(encoded)
    assert decoded === packet

    {:ok, encoded_again, _size} = ControlPacket.encode(decoded)
    assert encoded === encoded_again
  end

  test "publish qos1" do
    packet = %ControlPacket.Publish{
      topic_name: "test",
      payload: "test",
      packet_identifier: 1,
      qos_level: :at_least_once,
      properties: %{
        user_property: %{"test" => "test"},
        payload_format_indicator: 0
      }
    }

    {:ok, encoded, _size} = ControlPacket.encode(packet)

    {:ok, [decoded], _size} = ControlPacket.decode_buffer(encoded)
    assert decoded === packet

    {:ok, encoded_again, _size} = ControlPacket.encode(decoded)
    assert encoded === encoded_again
  end

  test "puback" do
    packet = %ControlPacket.Puback{
      packet_identifier: 1
    }

    {:ok, encoded, _size} = ControlPacket.encode(packet)

    {:ok, [decoded], _size} = ControlPacket.decode_buffer(encoded)
    assert decoded === packet

    {:ok, encoded_again, _size} = ControlPacket.encode(decoded)
    assert encoded === encoded_again
  end

  test "pubrec" do
    packet = %ControlPacket.Pubrec{
      packet_identifier: 1
    }

    {:ok, encoded, _size} = ControlPacket.encode(packet)

    {:ok, [decoded], _size} = ControlPacket.decode_buffer(encoded)
    assert decoded === packet

    {:ok, encoded_again, _size} = ControlPacket.encode(decoded)
    assert encoded === encoded_again
  end

  test "pubrel" do
    packet = %ControlPacket.Pubrec{
      packet_identifier: 1
    }

    {:ok, encoded, _size} = ControlPacket.encode(packet)

    {:ok, [decoded], _size} = ControlPacket.decode_buffer(encoded)
    assert decoded === packet

    {:ok, encoded_again, _size} = ControlPacket.encode(decoded)
    assert encoded === encoded_again
  end

  test "pubcomp" do
    packet = %ControlPacket.Pubrec{
      packet_identifier: 1
    }

    {:ok, encoded, _size} = ControlPacket.encode(packet)

    {:ok, [decoded], _size} = ControlPacket.decode_buffer(encoded)
    assert decoded === packet

    {:ok, encoded_again, _size} = ControlPacket.encode(decoded)
    assert encoded === encoded_again
  end

  test "subscribe" do
    packet = %ControlPacket.Subscribe{
      packet_identifier: 1,
      topic_filters: [
        {"test", %{retain_handling: :dont_send, rap: false, nl: false, qos: :at_most_once}},
        {"test2", %{retain_handling: :dont_send, rap: false, nl: true, qos: :at_least_once}}
      ]
    }

    {:ok, encoded, _size} = ControlPacket.encode(packet)

    {:ok, [decoded], _size} = ControlPacket.decode_buffer(encoded)
    assert decoded === packet

    {:ok, encoded_again, _size} = ControlPacket.encode(decoded)
    assert encoded === encoded_again
  end

  test "suback" do
    packet = %ControlPacket.Suback{
      packet_identifier: 1,
      reason_codes: [:granted_qos_1, :granted_qos_2]
    }

    {:ok, encoded, _size} = ControlPacket.encode(packet)

    {:ok, [decoded], _size} = ControlPacket.decode_buffer(encoded)
    assert decoded === packet

    {:ok, encoded_again, _size} = ControlPacket.encode(decoded)
    assert encoded === encoded_again
  end

  test "unsubscribe" do
    packet = %ControlPacket.Unsubscribe{
      packet_identifier: 1,
      topic_filters: ["test", "test2"]
    }

    {:ok, encoded, _size} = ControlPacket.encode(packet)

    {:ok, [decoded], _size} = ControlPacket.decode_buffer(encoded)
    assert decoded === packet

    {:ok, encoded_again, _size} = ControlPacket.encode(decoded)
    assert encoded === encoded_again
  end

  test "unsuback" do
    packet = %ControlPacket.Unsuback{
      packet_identifier: 1,
      reason_codes: [:success, :no_subscription_existed]
    }

    {:ok, encoded, _size} = ControlPacket.encode(packet)

    {:ok, [decoded], _size} = ControlPacket.decode_buffer(encoded)
    assert decoded === packet

    {:ok, encoded_again, _size} = ControlPacket.encode(decoded)
    assert encoded === encoded_again
  end

  test "pingreq" do
    packet = %ControlPacket.Pingreq{}

    {:ok, encoded, _size} = ControlPacket.encode(packet)

    {:ok, [decoded], _size} = ControlPacket.decode_buffer(encoded)
    assert decoded === packet

    {:ok, encoded_again, _size} = ControlPacket.encode(decoded)
    assert encoded === encoded_again
  end

  test "pingresp" do
    packet = %ControlPacket.Pingresp{}

    {:ok, encoded, _size} = ControlPacket.encode(packet)

    {:ok, [decoded], _size} = ControlPacket.decode_buffer(encoded)
    assert decoded === packet

    {:ok, encoded_again, _size} = ControlPacket.encode(decoded)
    assert encoded === encoded_again
  end

  test "disconnect" do
    packet = %ControlPacket.Disconnect{reason_code: :normal_disconnection}

    {:ok, encoded, _size} = ControlPacket.encode(packet)

    {:ok, [decoded], _size} = ControlPacket.decode_buffer(encoded)
    assert decoded === packet

    {:ok, encoded_again, _size} = ControlPacket.encode(decoded)
    assert encoded === encoded_again
  end

  test "auth" do
    packet = %ControlPacket.Auth{reason_code: :success}

    {:ok, encoded, _size} = ControlPacket.encode(packet)

    {:ok, [decoded], _size} = ControlPacket.decode_buffer(encoded)
    assert decoded === packet

    {:ok, encoded_again, _size} = ControlPacket.encode(decoded)
    assert encoded === encoded_again
  end
end
