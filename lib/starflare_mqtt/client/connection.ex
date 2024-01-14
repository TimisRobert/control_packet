defmodule StarflareMqtt.Client.Connection do
  @moduledoc false

  alias StarflareMqtt.Packet

  @behaviour :gen_statem

  defstruct [
    :host,
    :port,
    :username,
    :password,
    :clientid,
    :keep_alive,
    :properties,
    :socket,
    :buffer
  ]

  def start_link(opts) do
    {host, opts} = Keyword.pop!(opts, :host)
    {port, opts} = Keyword.pop!(opts, :port)
    {username, opts} = Keyword.pop(opts, :username, "")
    {password, opts} = Keyword.pop(opts, :password, "")

    :gen_statem.start_link(__MODULE__, {host, port, username, password}, opts)
  end

  def call(pid, packet) do
    :gen_statem.call(pid, {:send, packet})
  end

  def send_request(pid, packet) do
    :gen_statem.send_request(pid, {:send, packet})
  end

  def get_state(pid) do
    :sys.get_state(pid)
  end

  @impl true
  def init({host, port, username, password}) do
    data = %__MODULE__{
      host: host,
      port: port,
      username: username,
      password: password,
      buffer: ""
    }

    {:ok, :disconnected, data, [{:next_event, :internal, :connect}]}
  end

  @impl true
  def callback_mode, do: :handle_event_function

  @impl true
  def handle_event(:internal, :connect, :disconnected, data) do
    %__MODULE__{
      host: host,
      port: port,
      username: username,
      password: password
    } = data

    keep_alive = 60

    connect = %Packet.Connect{
      username: username,
      password: password,
      keep_alive: keep_alive,
      clean_start: true
    }

    opts = [:binary, packet: :raw, active: :once]

    with {:ok, socket} <- :gen_tcp.connect(to_charlist(host), port, opts),
         :ok <- send_packet(socket, connect) do
      data =
        data
        |> Map.put(:socket, socket)
        |> Map.put(:keep_alive, keep_alive)

      {:next_state, :connected, data}
    else
      _error ->
        {:keep_state_and_data, [{:timeout, :timer.seconds(1), :connect}]}
    end
  end

  def handle_event(:info, {:tcp, socket, packet}, :connected, %{socket: socket} = data) do
    :inet.setopts(socket, active: :once)

    with {:ok, packets, buffer} <- handle_buffer(data.buffer <> packet, data, []) do
      data = %{data | buffer: buffer}

      case handle_packets(packets, data, []) do
        list when is_list(list) ->
          {:keep_state, data, [{:timeout, :timer.seconds(data.keep_alive), :ping} | list]}

        next_state ->
          next_state
      end
    end
  end

  def handle_event(:info, {:tcp_closed, socket}, :connected, %{socket: socket} = data) do
    :gen_tcp.close(socket)
    data = %{data | socket: nil}

    {:next_state, :disconnected, data, [{:next_event, :internal, :connect}]}
  end

  def handle_event({:call, from}, {:send, packet}, :connected, %{socket: socket} = data) do
    case send_packet(socket, packet) do
      :ok ->
        Process.put(packet.packet_identifier, from)

        {:keep_state_and_data, [{:timeout, :timer.seconds(data.keep_alive), :ping}]}

      error ->
        {:keep_state_and_data,
         [{:reply, from, {:error, error}}, {:timeout, :timer.seconds(data.keep_alive), :ping}]}
    end
  end

  def handle_event({:call, from}, {:send, _packet}, :disconnected, _data) do
    {:keep_state_and_data, [{:reply, from, {:error, :disconnected}}]}
  end

  def handle_event(:timeout, :ping, :connected, %{socket: socket} = data) do
    case send_packet(socket, %Packet.Pingreq{}) do
      :ok -> :keep_state_and_data
      _error -> {:next_state, :disconnected, data}
    end
  end

  def handle_event(:timeout, :connect, :disconnected, _) do
    {:keep_state_and_data, [{:next_event, :internal, :connect}]}
  end

  defp handle_connection(%Packet.Connack{} = connack, data) do
    %Packet.Connack{properties: properties} = connack

    {assigned_client_identifier, properties} =
      Keyword.pop(properties, :assigned_client_identifier)

    data =
      if assigned_client_identifier,
        do: %{data | clientid: assigned_client_identifier},
        else: data

    {server_keep_alive, properties} = Keyword.pop(properties, :server_keep_alive)

    data =
      if server_keep_alive,
        do: %{data | keep_alive: server_keep_alive},
        else: data

    data = %{data | properties: properties}

    {:next_state, :connected, data, [{:timeout, :timer.seconds(data.keep_alive), :ping}]}
  end

  defp send_packet(socket, packet) do
    with {:ok, packet} <- Packet.encode(packet) do
      :gen_tcp.send(socket, packet)
    end
  end

  defp handle_buffer("", _data, list) do
    {:ok, list, ""}
  end

  defp handle_buffer(buffer, data, list) do
    case Packet.decode(buffer) do
      {:ok, nil, rest} ->
        {:ok, list, rest}

      {:ok, decoded_packet, rest} ->
        handle_buffer(rest, data, [decoded_packet | list])

      {:error, error} ->
        {:error, error}
    end
  end

  defp handle_packets([packet | packets], data, list) do
    case packet do
      %Packet.Connack{reason_code: :success} = connack ->
        handle_connection(connack, data)

      %Packet.Connack{reason_code: _reason_code} ->
        {:next_state, :disconnected, data, [{:timeout, :timer.seconds(1), :connect}]}

      %Packet.Disconnect{} ->
        {:next_state, :disconnected, data, [{:timeout, :timer.seconds(1), :connect}]}

      %Packet.Pingresp{} ->
        {:keep_state, data, [{:timeout, :timer.seconds(data.keep_alive), :ping}]}

      packet ->
        from = Process.delete(packet.packet_identifier)

        if from do
          handle_packets(packets, data, [{:reply, from, packet} | list])
        else
          handle_packets(packets, data, list)
        end
    end
  end

  defp handle_packets([], _data, list), do: list
end
