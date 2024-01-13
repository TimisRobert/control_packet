defmodule StarflareMqtt.Packet.Disconnect do
  @moduledoc false

  alias StarflareMqtt.Packet.Type.{Property, ReasonCode}

  defstruct [:reason_code, :properties]

  def decode(<<>>), do: {:ok, %__MODULE__{reason_code: :success}}

  def decode(data) do
    with {:ok, reason_code, rest} <- ReasonCode.decode(__MODULE__, data),
         {:ok, properties, _} <- Property.decode(rest) do
      {:ok,
       %__MODULE__{
         reason_code: reason_code,
         properties: properties
       }}
    end
  end

  def encode(%__MODULE__{reason_code: nil}), do: {:ok, <<>>}

  def encode(%__MODULE__{} = disconnect) do
    %__MODULE__{
      reason_code: reason_code,
      properties: properties
    } = disconnect

    with {:ok, data} <- ReasonCode.encode(__MODULE__, reason_code),
         encoded_data <- data,
         {:ok, data} <- Property.encode(properties),
         encoded_data <- data <> encoded_data do
      {:ok, encoded_data}
    end
  end
end
