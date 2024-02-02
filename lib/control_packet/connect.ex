defmodule ControlPacket.Connect do
  @moduledoc false

  defstruct [
    :clientid,
    :properties,
    :clean_start,
    :will,
    :will_retain,
    :will_qos,
    :username,
    :password,
    :keep_alive
  ]

  alias ControlPacket.Properties

  def new(opts \\ []) do
    case Keyword.validate(opts,
           clientid: "",
           properties: [],
           clean_start: false,
           will: nil,
           will_retain: false,
           will_qos: :at_most_once,
           username: "",
           password: "",
           keep_alive: 60
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
