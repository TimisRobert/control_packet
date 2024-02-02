defmodule ControlPacket.Unsuback do
  @moduledoc false

  defstruct [:packet_identifier, :reason_codes, :properties]

  alias ControlPacket.Properties

  def new(reason_codes, opts \\ []) do
    case Keyword.validate(opts, properties: [], packet_identifier: nil) do
      {:ok, opts} ->
        {properties, opts} = Keyword.pop!(opts, :properties)

        with {:ok, properties} <- Properties.new(properties) do
          opts =
            Keyword.put(opts, :reason_codes, reason_codes)
            |> Keyword.put(:properties, properties)

          {:ok, struct!(__MODULE__, opts)}
        end

      {:error, _} ->
        {:error, :malformed_packet}
    end
  end
end
