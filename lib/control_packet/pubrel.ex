defmodule ControlPacket.Pubrel do
  @moduledoc false

  defstruct [:packet_identifier, :reason_code, :properties]

  alias ControlPacket.Properties

  def new(opts \\ []) do
    case Keyword.validate(opts, packet_identifier: nil, reason_code: :success, properties: []) do
      {:ok, opts} ->
        case Keyword.fetch(opts, :packet_identifier) do
          {:ok, packet_identifier} when is_number(packet_identifier) and packet_identifier > 0 ->
            {properties, opts} = Keyword.pop!(opts, :properties)

            with {:ok, properties} <- Properties.new(properties) do
              opts =
                Keyword.put(opts, :packet_identifier, packet_identifier)
                |> Keyword.put(:properties, properties)

              struct(__MODULE__, opts)
            end

          _ ->
            {:error, :malformed_packet}
        end

      {:error, _} ->
        {:error, :malformed_packet}
    end
  end
end
