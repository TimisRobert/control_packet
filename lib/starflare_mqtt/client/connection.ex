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
    {username, opts} = Keyword.pop!(opts, :username)
    {password, opts} = Keyword.pop!(opts, :password)

    :gen_statem.start_link(__MODULE__, {host, port, username, password}, opts)
  end

  @impl true
  def init({host, port, username, password}) do
    data = %__MODULE__{
      host: host,
      port: port,
      username: username,
      password: password
    }

    {:ok, :disconnected, data, [{:next_event, :internal, :connecting}]}
  end

  @impl true
  def callback_mode, do: :handle_event_function

  @impl true
  def handle_event(:internal, :connecting, :disconnected, data) do
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
         {:ok, packet} <- Packet.encode(connect),
         :ok <- :gen_tcp.send(socket, packet) do
      data =
        data
        |> Map.put(:socket, socket)
        |> Map.put(:keep_alive, keep_alive)

      {:next_state, :connecting, data}
    else
      error -> {:stop, error}
    end
  end

  def handle_event(:info, {:tcp, socket, packet}, :connecting, %{socket: socket} = data) do
    :inet.setopts(socket, active: :once)

    with {:ok, packet} <- Packet.decode(packet) do
      case packet do
        %Packet.Connack{reason_code: :success} = connack ->
          %Packet.Connack{properties: properties} = connack

          data =
            data
            |> Map.put(:properties, properties)

          assigned_client_identifier = Map.get(properties, :assigned_client_identifier)

          data =
            if assigned_client_identifier do
              data
              |> Map.put(:clientid, assigned_client_identifier)
            else
              data
            end

          server_keep_alive = Map.get(properties, :server_keep_alive)

          data =
            if server_keep_alive do
              data
              |> Map.put(:keep_alive, server_keep_alive)
            else
              data
            end

          keep_alive = Map.get(data, :keep_alive)
          {:next_state, :connected, data, [{:timeout, :timer.seconds(keep_alive), :ping}]}

        %Packet.Connack{reason_code: reason_code} ->
          {:stop, reason_code}

        %Packet.Pingresp{} ->
          keep_alive = Map.get(data, :keep_alive)
          {:next_state, :connected, data, [{:timeout, :timer.seconds(keep_alive), :ping}]}

        _ ->
          :stop
      end
    end
  end

  def handle_event(:info, {:tcp_closed, socket}, :connected, %{socket: socket} = data) do
    :gen_tcp.close(socket)
    {:next_state, :disconnected, %{data | socket: nil}, [{:next_event, :internal, :connecting}]}
  end

  def handle_event(:timeout, :ping, :connected, %{socket: socket} = data) do
    pingreq = %Packet.Pingreq{}

    with {:ok, packet} <- Packet.encode(pingreq),
         :ok <- :gen_tcp.send(socket, packet) do
      {:next_state, :connecting, data}
    end
  end

  def handle_event({:call, from}, {:send, data}, :connected, %{socket: socket}) do
    with {:ok, packet} <- Packet.encode(data),
         :ok <- :gen_tcp.send(socket, packet) do
      {:keep_state_and_data, {:reply, from, :ok}}
    else
      error ->
        {:keep_state_and_data, {:reply, from, {:error, error}}}
    end
  end

  def handle_event({:call, from}, {:send, data}, state, %{socket: socket})
      when state in [:connecting, :disconnected] do
    with {:ok, packet} <- Packet.encode(data),
         :ok <- :gen_tcp.send(socket, packet) do
      {:keep_state_and_data, {:reply, from, :ok}, [{:postpone}]}
    else
      error ->
        {:keep_state_and_data, {:reply, from, {:error, error}}}
    end
  end
end
