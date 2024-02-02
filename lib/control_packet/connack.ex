defmodule ControlPacket.Connack do
  @moduledoc false

  defstruct [:session_present, :reason_code, :properties]

  alias ControlPacket.Properties

  def new(opts \\ []) do
    case Keyword.validate(opts,
           session_present: false,
           reason_code: :success,
           properties: []
         ) do
      {:ok, opts} ->
        {properties, opts} = Keyword.pop!(opts, :properties)

        with {:ok, properties} <- Properties.new(properties) do
          opts = Keyword.put(opts, :properties, properties)
          struct(__MODULE__, opts)
        end

      {:error, _} ->
        {:error, :malformed_packet}
    end
  end
end
