defmodule ControlPacketTest do
  use ExUnit.Case
  doctest ControlPacket

  test "connect" do
    packet =
      ControlPacket.Connect.new(
        username: "test",
        password: "test",
        clientid: "one"
      )

    {:ok, encoded, _size} = ControlPacket.encode(packet)

    {:ok, [decoded], _size} = ControlPacket.decode_buffer(encoded)
    assert decoded === packet

    {:ok, encoded_again, _size} = ControlPacket.encode(decoded)
    assert encoded === encoded_again
  end

  test "connack" do
    packet = ControlPacket.Connack.new()

    {:ok, encoded, _size} = ControlPacket.encode(packet)

    {:ok, [decoded], _size} = ControlPacket.decode_buffer(encoded)
    assert decoded === packet

    {:ok, encoded_again, _size} = ControlPacket.encode(decoded)
    assert encoded === encoded_again
  end

  test "publish qos0" do
    packet = ControlPacket.Publish.new("test", "test", qos_level: :at_most_once)

    {:ok, encoded, _size} = ControlPacket.encode(packet)

    {:ok, [decoded], _size} = ControlPacket.decode_buffer(encoded)
    assert decoded === packet

    {:ok, encoded_again, _size} = ControlPacket.encode(decoded)
    assert encoded === encoded_again
  end

  test "publish qos1" do
    packet =
      ControlPacket.Publish.new("test", "test",
        qos_level: :at_least_once,
        packet_identifier: 1,
        properties: [
          user_property: {"test", "test"},
          payload_format_indicator: 0
        ]
      )

    {:ok, encoded, _size} = ControlPacket.encode(packet)

    {:ok, [decoded], _size} = ControlPacket.decode_buffer(encoded)
    assert decoded === packet

    {:ok, encoded_again, _size} = ControlPacket.encode(decoded)
    assert encoded === encoded_again
  end

  test "puback" do
    packet = ControlPacket.Puback.new(packet_identifier: 1)

    {:ok, encoded, _size} = ControlPacket.encode(packet)

    {:ok, [decoded], _size} = ControlPacket.decode_buffer(encoded)
    assert decoded === packet

    {:ok, encoded_again, _size} = ControlPacket.encode(decoded)
    assert encoded === encoded_again
  end

  test "pubrec" do
    packet = ControlPacket.Pubrec.new(packet_identifier: 1)

    {:ok, encoded, _size} = ControlPacket.encode(packet)

    {:ok, [decoded], _size} = ControlPacket.decode_buffer(encoded)
    assert decoded === packet

    {:ok, encoded_again, _size} = ControlPacket.encode(decoded)
    assert encoded === encoded_again
  end

  test "pubrel" do
    packet = ControlPacket.Pubrel.new(packet_identifier: 1)

    {:ok, encoded, _size} = ControlPacket.encode(packet)

    {:ok, [decoded], _size} = ControlPacket.decode_buffer(encoded)
    assert decoded === packet

    {:ok, encoded_again, _size} = ControlPacket.encode(decoded)
    assert encoded === encoded_again
  end

  test "pubcomp" do
    packet = ControlPacket.Pubcomp.new(packet_identifier: 1)

    {:ok, encoded, _size} = ControlPacket.encode(packet)

    {:ok, [decoded], _size} = ControlPacket.decode_buffer(encoded)
    assert decoded === packet

    {:ok, encoded_again, _size} = ControlPacket.encode(decoded)
    assert encoded === encoded_again
  end

  test "subscribe" do
    packet =
      ControlPacket.Subscribe.new(
        [
          {"test",
           retain_handling: :send_when_subscribed, rap: false, nl: false, qos: :at_least_once},
          {"test2",
           retain_handling: :send_when_subscribed, rap: false, nl: false, qos: :at_least_once}
        ],
        packet_identifier: 1
      )

    {:ok, encoded, _size} = ControlPacket.encode(packet)

    {:ok, [decoded], _size} = ControlPacket.decode_buffer(encoded)
    assert decoded === packet

    {:ok, encoded_again, _size} = ControlPacket.encode(decoded)
    assert encoded === encoded_again
  end

  test "suback" do
    packet =
      ControlPacket.Suback.new([:granted_qos_1, :granted_qos_2], packet_identifier: 1)

    {:ok, encoded, _size} = ControlPacket.encode(packet)

    {:ok, [decoded], _size} = ControlPacket.decode_buffer(encoded)
    assert decoded === packet

    {:ok, encoded_again, _size} = ControlPacket.encode(decoded)
    assert encoded === encoded_again
  end

  test "unsubscribe" do
    packet = ControlPacket.Unsubscribe.new(["test", "test2"], packet_identifier: 1)

    {:ok, encoded, _size} = ControlPacket.encode(packet)

    {:ok, [decoded], _size} = ControlPacket.decode_buffer(encoded)
    assert decoded === packet

    {:ok, encoded_again, _size} = ControlPacket.encode(decoded)
    assert encoded === encoded_again
  end

  test "unsuback" do
    packet =
      ControlPacket.Unsuback.new([:success, :no_subscription_existed], packet_identifier: 1)

    {:ok, encoded, _size} = ControlPacket.encode(packet)

    {:ok, [decoded], _size} = ControlPacket.decode_buffer(encoded)
    assert decoded === packet

    {:ok, encoded_again, _size} = ControlPacket.encode(decoded)
    assert encoded === encoded_again
  end

  test "pingreq" do
    packet = ControlPacket.Pingreq.new()

    {:ok, encoded, _size} = ControlPacket.encode(packet)

    {:ok, [decoded], _size} = ControlPacket.decode_buffer(encoded)
    assert decoded === packet

    {:ok, encoded_again, _size} = ControlPacket.encode(decoded)
    assert encoded === encoded_again
  end

  test "pingresp" do
    packet = ControlPacket.Pingresp.new()

    {:ok, encoded, _size} = ControlPacket.encode(packet)

    {:ok, [decoded], _size} = ControlPacket.decode_buffer(encoded)
    assert decoded === packet

    {:ok, encoded_again, _size} = ControlPacket.encode(decoded)
    assert encoded === encoded_again
  end

  test "disconnect" do
    packet = ControlPacket.Disconnect.new()

    {:ok, encoded, _size} = ControlPacket.encode(packet)

    {:ok, [decoded], _size} = ControlPacket.decode_buffer(encoded)
    assert decoded === packet

    {:ok, encoded_again, _size} = ControlPacket.encode(decoded)
    assert encoded === encoded_again
  end

  test "auth" do
    packet = ControlPacket.Auth.new()

    {:ok, encoded, _size} = ControlPacket.encode(packet)

    {:ok, [decoded], _size} = ControlPacket.decode_buffer(encoded)
    assert decoded === packet

    {:ok, encoded_again, _size} = ControlPacket.encode(decoded)
    assert encoded === encoded_again
  end
end
