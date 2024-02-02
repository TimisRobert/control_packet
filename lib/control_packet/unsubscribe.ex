defmodule ControlPacket.Unsubscribe do
  @moduledoc false

  defstruct [:packet_identifier, :topic_filters, :properties]

  alias ControlPacket.Properties

  def new(topic_filters, opts \\ []) do
    case Keyword.validate(opts, properties: [], packet_identifier: nil) do
      {:ok, opts} ->
        {properties, opts} = Keyword.pop!(opts, :properties)

        with {:ok, properties} <- Properties.new(properties) do
          opts =
            Keyword.put(opts, :topic_filters, topic_filters)
            |> Keyword.put(:properties, properties)

          {:ok, struct!(__MODULE__, opts)}
        end

      {:error, _} ->
        {:error, :malformed_packet}
    end
  end
end
