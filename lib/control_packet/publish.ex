defmodule ControlPacket.Publish do
  @moduledoc false

  defstruct [
    :dup_flag,
    :qos_level,
    :retain,
    :topic_name,
    :packet_identifier,
    :properties,
    :payload
  ]

  alias ControlPacket.Properties

  def new(topic_name, payload, opts \\ []) do
    case Keyword.validate(opts,
           packet_identifier: nil,
           dup_flag: false,
           qos_level: :at_most_once,
           retain: false,
           properties: []
         ) do
      {:ok, opts} ->
        case {Keyword.fetch(opts, :qos_level), Keyword.fetch(opts, :packet_identifier)} do
          {{:ok, :at_most_once}, _} ->
            {properties, opts} = Keyword.pop!(opts, :properties)

            with {:ok, properties} <- Properties.new(properties) do
              opts =
                Keyword.put(opts, :topic_name, topic_name)
                |> Keyword.put(:payload, payload)
                |> Keyword.put(:properties, properties)

              {:ok, struct!(__MODULE__, opts)}
            end

          {_, {:ok, packet_identifier}}
          when is_number(packet_identifier) and packet_identifier > 0 ->
            {properties, opts} = Keyword.pop!(opts, :properties)

            with {:ok, properties} <- Properties.new(properties) do
              opts =
                Keyword.put(opts, :packet_identifier, packet_identifier)
                |> Keyword.put(:topic_name, topic_name)
                |> Keyword.put(:payload, payload)
                |> Keyword.put(:properties, properties)

              {:ok, struct!(__MODULE__, opts)}
            end

          _ ->
            {:error, :malformed_packet}
        end

      {:error, _} ->
        {:error, :malformed_packet}
    end
  end
end
