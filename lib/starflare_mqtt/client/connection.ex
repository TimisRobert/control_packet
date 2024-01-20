defmodule StarflareMqtt.Client.Connection do
  @moduledoc false

  alias StarflareMqtt.ControlPacket

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
    {clientid, opts} = Keyword.pop(opts, :clientid, "")
    {username, opts} = Keyword.pop(opts, :username, "")
    {password, opts} = Keyword.pop(opts, :password, "")

    :gen_statem.start_link(__MODULE__, {host, port, clientid, username, password}, opts)
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
  def init({host, port, clientid, username, password}) do
    data = %__MODULE__{
      host: host,
      port: port,
      clientid: clientid,
      username: username,
      password: password,
      buffer: ""
    }

    {:ok, :connecting, data, [{:next_event, :internal, :connect}]}
  end

  @impl true
  def callback_mode, do: :handle_event_function

  @impl true
  def handle_event(:internal, :connect, :connecting, data) do
    %__MODULE__{
      host: host,
      port: port,
      clientid: clientid,
      username: username,
      password: password
    } = data

    keep_alive = 5

    connect = %ControlPacket.Connect{
      clientid: clientid,
      username: username,
      password: password,
      keep_alive: keep_alive,
      clean_start: true
    }

    opts = [:binary, packet: :raw, active: :once]

    with {:ok, socket} <- :gen_tcp.connect(to_charlist(host), port, opts),
         :ok <- send_packet(socket, connect) do
      data = %{data | socket: socket}
      data = %{data | keep_alive: keep_alive}

      {:keep_state, data}
    else
      _error -> {:next_state, :disconnected, data, connect_timeout(data)}
    end
  end

  def handle_event(:info, {:tcp, socket, packet}, state, %{socket: socket} = data)
      when state in [:connecting, :connected] do
    :inet.setopts(socket, active: :once)

    with {:ok, packets, buffer} <- handle_buffer(data.buffer <> packet, []) do
      data = %{data | buffer: buffer}

      handle_packets(packets, data, [])
    end
  end

  def handle_event(:info, {:tcp_closed, socket}, _state, %{socket: socket} = data) do
    :gen_tcp.close(socket)
    data = %{data | socket: nil}
    {:next_state, :disconnected, data, connect_timeout(data)}
  end

  def handle_event({:call, from}, {:send, packet}, :connected, %{socket: socket} = data) do
    case send_packet(socket, packet) do
      :ok ->
        if Map.has_key?(packet, :packet_identifier),
          do: Process.put(packet.packet_identifier, from)

        {:keep_state_and_data, ping_timeout(data)}

      error ->
        {:keep_state_and_data, [{:reply, from, {:error, error}}, ping_timeout(data)]}
    end
  end

  def handle_event({:call, from}, {:send, _packet}, state, data) do
    {:keep_state_and_data, [{:reply, from, {:error, state}}, connect_timeout(data)]}
  end

  def handle_event(:timeout, :ping, :connected, %{socket: socket} = data) do
    case send_packet(socket, %ControlPacket.Pingreq{}) do
      :ok -> :keep_state_and_data
      _error -> {:next_state, :disconnected, data, connect_timeout(data)}
    end
  end

  def handle_event(:timeout, :connect, :disconnected, data) do
    {:next_state, :connecting, data, [{:next_event, :internal, :connect}]}
  end

  defp send_packet(socket, packet) do
    packet = ControlPacket.encode(packet)
    :gen_tcp.send(socket, packet)
  end

  defp handle_buffer("", list) do
    {:ok, list, ""}
  end

  defp handle_buffer(buffer, list) do
    case ControlPacket.decode(buffer) do
      # packet ->
      #   {:ok, list, rest}

      decoded_packet ->
        handle_buffer(<<>>, [decoded_packet | list])

        # {:error, error} ->
        #   {:error, error}
    end
  end

  defp handle_packets(
         [%ControlPacket.Connack{reason_code: :success} = connack | _packets],
         data,
         _list
       ) do
    %ControlPacket.Connack{properties: properties} = connack

    data =
      case Keyword.get(properties, :assigned_client_identifier) do
        nil -> data
        assigned_client_identifier -> %{data | clientid: assigned_client_identifier}
      end

    data =
      case Keyword.get(properties, :server_keep_alive) do
        nil -> data
        server_keep_alive -> %{data | keep_alive: server_keep_alive}
      end

    data = %{data | properties: properties}

    {:next_state, :connected, data, ping_timeout(data)}
  end

  defp handle_packets([%ControlPacket.Connack{reason_code: _reason_code} | _packets], data, _list) do
    {:next_state, :disconnected, data, connect_timeout(data)}
  end

  defp handle_packets(
         [%ControlPacket.Disconnect{reason_code: _reason_code} | _packets],
         data,
         _list
       ) do
    {:next_state, :disconnected, data, connect_timeout(data)}
  end

  defp handle_packets([%ControlPacket.Pingresp{} | _packets], data, _list) do
    {:keep_state, data, ping_timeout(data)}
  end

  defp handle_packets([packet | packets], data, list) do
    case Process.delete(packet.packet_identifier) do
      nil -> handle_packets(packets, data, list)
      from -> handle_packets(packets, data, [{:reply, from, packet} | list])
    end
  end

  defp handle_packets([], data, list), do: {:keep_state, data, [ping_timeout(data) | list]}

  defp ping_timeout(data), do: {:timeout, :timer.seconds(data.keep_alive), :ping}
  defp connect_timeout(_data), do: {:timeout, :timer.seconds(1), :connect}
end
