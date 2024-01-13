defmodule StarflareMqtt.Client.Connection do
  @moduledoc false

  alias StarflareMqtt.Packet

  @behaviour :gen_statem

  defstruct [
    :host,
    :port,
    :username,
    :password,
    :socket,
    :clientid,
    :keep_alive,
    :properties
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
      password: password
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

    opts = [:binary, packet: :raw, active: true]

    with {:ok, socket} <- :gen_tcp.connect(to_charlist(host), port, opts),
         :ok <- send_packet(socket, connect) do
      data =
        data
        |> Map.put(:socket, socket)
        |> Map.put(:keep_alive, keep_alive)

      {:next_state, :connecting, data}
    else
      _error ->
        {:keep_state_and_data, [{:timeout, :timer.seconds(1), :connect}]}
    end
  end

  def handle_event(:info, {:tcp, socket, packet}, :connecting, %{socket: socket} = data) do
    case Packet.decode(packet) do
      {:ok, decoded_packet, ""} ->
        handle_connecting(decoded_packet, data)

      {:error, error} ->
        {:stop, error}
    end
  end

  def handle_event(:info, {:tcp, socket, packet}, :connected, %{socket: socket} = data) do
    {:keep_state_and_data,
     [{:timeout, :timer.seconds(data.keep_alive), :ping} | handle_packets(packet, data, [])]}
  end

  def handle_event(:info, {:tcp_closed, socket}, :connected, %{socket: socket} = data) do
    :gen_tcp.close(socket)

    {:next_state, :disconnected, %{data | socket: nil},
     [
       {:next_event, :internal, :connect}
     ]}
  end

  def handle_event(:timeout, :ping, :connected, %{socket: socket} = data) do
    case send_packet(socket, %Packet.Pingreq{}) do
      :ok -> {:next_state, :connecting, data}
      _error -> {:next_state, :disconnected, data}
    end
  end

  def handle_event(:timeout, :connect, :disconnected, _) do
    {:keep_state_and_data, [{:next_event, :internal, :connect}]}
  end

  def handle_event(
        {:call, from},
        {:send, %Packet.Publish{} = publish},
        :connected,
        %{socket: socket} = data
      ) do
    case send_packet(socket, publish) do
      :ok ->
        case publish.qos_level do
          :at_most_once ->
            {:keep_state_and_data,
             [
               {:reply, from, :ok},
               {:timeout, :timer.seconds(data.keep_alive), :ping}
             ]}

          _ ->
            Process.put(publish.packet_identifier, from)

            {:keep_state_and_data,
             [
               {:timeout, :timer.seconds(data.keep_alive), :ping}
             ]}
        end

      error ->
        {:keep_state_and_data,
         [
           {:reply, from, {:error, error}},
           {:timeout, :timer.seconds(data.keep_alive), :ping}
         ]}
    end
  end

  def handle_event(
        {:call, from},
        {:send, %Packet.Subscribe{} = subscribe},
        :connected,
        %{socket: socket} = data
      ) do
    case send_packet(socket, subscribe) do
      :ok ->
        Process.put(subscribe.packet_identifier, from)

        {:keep_state_and_data,
         [
           {:timeout, :timer.seconds(data.keep_alive), :ping}
         ]}

      error ->
        {:keep_state_and_data,
         [
           {:reply, from, {:error, error}},
           {:timeout, :timer.seconds(data.keep_alive), :ping}
         ]}
    end
  end

  def handle_event({:call, from}, {:send, packet}, :connected, %{socket: socket} = data) do
    case send_packet(socket, packet) do
      :ok ->
        {:keep_state_and_data,
         [
           {:reply, from, :ok},
           {:timeout, :timer.seconds(data.keep_alive), :ping}
         ]}

      error ->
        {:keep_state_and_data,
         [
           {:reply, from, {:error, error}},
           {:timeout, :timer.seconds(data.keep_alive), :ping}
         ]}
    end
  end

  defp send_packet(socket, packet) do
    with {:ok, packet} <- Packet.encode(packet) do
      :gen_tcp.send(socket, packet)
    end
  end

  defp handle_connecting(%Packet.Connack{reason_code: :success} = connack, data) do
    %Packet.Connack{properties: properties} = connack

    {assigned_client_identifier, properties} =
      Keyword.pop(properties, :assigned_client_identifier)

    data =
      if assigned_client_identifier do
        data
        |> Map.put(:clientid, assigned_client_identifier)
      else
        data
      end

    {server_keep_alive, properties} = Keyword.pop(properties, :server_keep_alive)

    data =
      if server_keep_alive do
        data
        |> Map.put(:keep_alive, server_keep_alive)
      else
        data
      end

    data =
      data
      |> Map.put(:properties, properties)

    {:next_state, :connected, data,
     [
       {:timeout, :timer.seconds(data.keep_alive), :ping}
     ]}
  end

  defp handle_connecting(%Packet.Connack{reason_code: reason_code}, _) do
    {:stop, reason_code}
  end

  defp handle_connecting(%Packet.Disconnect{reason_code: reason_code}, _) do
    {:stop, reason_code}
  end

  defp handle_connecting(%Packet.Pingresp{}, data) do
    {:next_state, :connected, data,
     [
       {:timeout, :timer.seconds(data.keep_alive), :ping}
     ]}
  end

  defp handle_packets(packets, data, list) do
    case Packet.decode(packets) do
      {:ok, decoded_packet, rest} when byte_size(rest) == 0 ->
        Enum.reject([handle_packet(decoded_packet, data) | list], &is_nil/1)

      {:ok, decoded_packet, rest} ->
        handle_packets(rest, data, [handle_packet(decoded_packet, data) | list])

      {:error, error} ->
        {:stop, error}
    end
  end

  defp handle_packet(%Packet.Suback{} = suback, _) do
    from = Process.get(suback.packet_identifier)

    {:reply, from, :ok}
  end

  defp handle_packet(%Packet.Puback{} = puback, _) do
    from = Process.get(puback.packet_identifier)

    {:reply, from, :ok}
  end

  defp handle_packet(%Packet.Pubrec{} = pubrec, %{socket: socket}) do
    from = Process.get(pubrec.packet_identifier)

    pubrel = %Packet.Pubrel{
      packet_identifier: pubrec.packet_identifier
    }

    case send_packet(socket, pubrel) do
      :ok ->
        nil

      error ->
        {:reply, from, {:error, error}}
    end
  end

  defp handle_packet(%Packet.Pubcomp{} = pubcomp, _) do
    from = Process.get(pubcomp.packet_identifier)
    Process.delete(pubcomp.packet_identifier)

    {:reply, from, :ok}
  end
end
