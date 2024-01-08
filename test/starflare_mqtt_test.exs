defmodule StarflareMqttTest do
  use ExUnit.Case
  doctest StarflareMqtt

  test "greets the world" do
    assert StarflareMqtt.hello() == :world
  end
end
