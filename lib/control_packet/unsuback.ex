defmodule ControlPacket.Unsuback do
  @moduledoc false

  defstruct [:packet_identifier, :reason_codes, :properties]

  alias ControlPacket.Properties

  def new(reason_codes, opts \\ []) do
    case Keyword.validate(opts, properties: [], packet_identifier: nil) do
      {:ok, opts} ->
        case Keyword.fetch(opts, :packet_identifier) do
          {:ok, packet_identifier} when is_number(packet_identifier) and packet_identifier > 0 ->
            {properties, opts} = Keyword.pop!(opts, :properties)

            with {:ok, properties} <- Properties.new(properties) do
              opts =
                Keyword.put(opts, :packet_identifier, packet_identifier)
                |> Keyword.put(:reason_codes, reason_codes)
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
