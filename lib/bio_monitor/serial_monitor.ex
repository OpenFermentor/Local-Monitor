defmodule BioMonitor.SerialMonitor do
  use GenServer

  @moduledoc """
    The SerialMonitor is in charge of the serial communication with the sensors
  """

  @name SerialMonitor

  @port_speed 9_600
  @read_delay_ms 30_000
  @new_line "\n"

  #User API
  def start_link() do
    GenServer.start_link(__MODULE__, :ok, [name: @name])
  end

  def get_ports() do
    GenServer.call(@name, :get_ports)
  end

  def set_port(port = %{type: _, data: _}) do
    GenServer.call(@name, {:set_port, port})
  end

  def get_readings() do
    GenServer.call(@name, :get_readings)
  end

  def send_command(command = %{sensor: _, command: _}) do
    GenServer.call(@name, {:send_command, command})
  end

  #Callbacks
  def init(:ok) do
    IO.puts 'Starting serial monitor...'
    {:ok, pid} = Nerves.UART.start_link
    {:ok, %{serial_pid: pid, ports: %{}}}
  end

  def handle_call(:get_ports, _from, state) do
    {:reply, {:ok, Nerves.UART.enumerate}, state}
  end

  def handle_call({:set_port, %{type: type, data: port}}, _from, state) do
    if Map.has_key?(state.ports, type) do
      {:reply, :error, state}
    end
    result = Nerves.UART.open(state.serial_pid, port.port, speed: @port_speed, active: false)
    case result do
      :ok ->
        {:reply, result, %{state | ports: Map.put(state.ports, type, port)}}
      _ ->
        {:reply, :error, state}
    end
  end

  def handle_call(:get_readings, _from, state) do
    {:reply, {:ok, state |> read_from_ports}, state}
  end

  def handle_call({:send_command, %{sensor: sensor, command: command}}, _from, state) do
    unless Map.has_key?(state.ports, sensor) do
      {:reply, :error, state}
    end
    result = Nerves.UART.write(state.serial_pid, command)
    {:reply, (if result == :ok, do: result, else: :error), state}
  end

  defp read_from_ports(state) do
    state.ports
    |> Enum.map(fn {type, data} ->
        _ = Nerves.UART.write(state.serial_pid, data.get_cmd)
       {type, read_from_port(state, type, data.port)}
       end)
    |> Enum.into(%{})
  end

  defp read_from_port(state, type, port) do
    case Nerves.UART.read(state.serial_pid, @read_delay_ms) do
      {:ok, value} ->
        IO.puts(value)
        unless is_binary(value) && String.valid?(value) do
          ""
        end

        if String.contains? value, @new_line do
          value
        else
          value <> read_from_port(state, type, port)
        end
      _ -> ""
    end
  end
end
