defmodule BioMonitor.SerialMonitor do
  use GenServer

  @moduledoc """
    The SerialMonitor is in charge of the serial communication with the sensors
  """

  @name SerialMonitor

  @port_speed 9_600
  @read_delay_ms 30_000
  @new_line "\n"

  @error_opening_port "The port could not be opened"
  @error_undefined_sensor "The sensor is undefined"
  @error_sending_command "The command could not be sent"

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, [name: @name])
  end

  @doc """
  Returns a list of available ports and the devices connected to them
  """
  def get_ports() do
    GenServer.call(@name, :get_ports)
  end

  @doc """
  Adds the sensors whose information comes through the device connected in port

  port: String identifying the device. Use `get_ports` to obtain the information
  sensors: Key value pair, where the key is an atom representing the type of
           the sensor, and the value is the command to fetch the data

  ## Examples

  add_sensor("COM4", %{temp => "getTemp", ph => "getPh"})
  """
  def add_sensors(port, sensors) do
    GenServer.call(@name, {:add_sensors, %{port => port, sensors => sensors}})
  end

  @doc """
  Retrieves the readings for the registered sensors

  ## Examples
  If :temp and :ph sensors are defined, then the returned value would be:

  %{
    temp => 32.3,
    ph => 9
  }
  """
  def get_readings() do
    GenServer.call(@name, :get_readings)
  end

  @doc """
  Sends a command to the sensor.

  sensor: Atom identifying the sensor for the communication
  command: The String instruction to be sent to the sensor
  """
  def send_command(sensor, command) do
    GenServer.call(@name, {:send_command, %{sensor => sensor, command => command}})
  end

  @doc """
  State structure:
  %{
    serial_pid: The pid of the process that handles serial connectivity
    sensors: Key value pair, where the key is an atom representing the type of
             the sensor, and the value is the command to fetch the data
  }

  ## Examples

  %{
    serial_pid: 1234,
    sensors: %{
      %{temp => "getTemp"},
      %{ph => "getPh"}
    }
  }
  """
  def init(:ok) do
    {:ok, pid} = Nerves.UART.start_link
    {:ok, %{serial_pid: pid, sensors: %{}}}
  end

  @doc """
  Lists the available ports in the device with the connected devices information,
  such as manufacter id, etc.
  """
  def handle_call(:get_ports, _from, state) do
    {:reply, {:ok, Nerves.UART.enumerate}, state}
  end

  @doc """
  Register the sensors to read and execute commands.
  Data format: %{
    port: The port of the device to establish communication,
    sensors: Key value pair, where the key is an atom representing the type of
             the sensor, and the value is the command to fetch the data
  }

  ## Examples

  %{
    port: "COM3",
    sensors: %{
      %{temp => "getTemp"},
      %{ph => "getPh"}
    }
  }
  """
  def handle_call({:add_sensors, %{port: port, sensors: sensors}}, _from, state) do
    result = Enum.reduce sensors, state, fn({sensor, read_command}, acc) ->
      if acc == :error, do: :error, else: acc |> add_sensor(port, sensor, read_command)
    end
    case result do
      :error ->
        {:reply, {:error, @error_opening_port}, state}
      updated_state ->
        {:reply, :ok, updated_state}
    end
  end

  @doc """
  Retrieves a hash of key value pairs containing the readings for each of the
  registered sensors.

  ## Example

  %{
    %{temp => 28.0}
    %{ph => 7,1}
  }
  """
  def handle_call(:get_readings, _from, state) do
    {:reply, {:ok, state |> get_sensor_readings}, state}
  end

  @doc """
  Sends the `command` to the specified registered `sensor`
  """
  def handle_call({:send_command, %{sensor: sensor, command: command}}, _from, state) do
    unless state |> has_sensor(sensor) do
      {:reply, {:error, @error_undefined_sensor}, state}
    end
    result = Nerves.UART.write(state.serial_pid, command)
    {:reply, (if result == :ok, do: result, else: {:error, @error_sending_command}), state}
  end

  # Register a new sensor.
  # If no sensors are present, then the port communication is opened.

  # state: The state of the GenServer
  # port: The port where the device is connected
  # sensor: The type identifier of the sensor to be added
  # read_command: The command needed to fetch information from the sensor
  defp add_sensor(state, port, sensor, read_command) do
    if state |> has_sensor(sensor) do
      {:reply, :ok, state |> update_sensor(sensor, read_command)}
    end
    case state |> open_device_connection(port) do
      :ok ->
        %{state | state.sensors => state.sensors |> Map.put(sensor, read_command)}
      _ ->
        :error
    end
  end

  # Opens the connection to the device in the given port
  #
  # port: The port where the device is located.
  defp open_device_connection(state, port) do
    if state.sensors |> Map.keys == [] do
      :ok
    end
    Nerves.UART.open(state.serial_pid, port, speed: @port_speed, active: false)
  end

  # Returns wheather the sensor is registered
  defp has_sensor(state, sensor) do
    Map.has_key?(state.sensors, sensor)
  end

  # Updates the sensor information with the new read_command
  defp update_sensor(state, sensor, read_command) do
    %{state.sensors | sensor => read_command}
  end

  # Returns the readings for the registered sensors
  defp get_sensor_readings(state) do
    state.sensors
    |> Enum.map(fn {sensor, read_command} ->
        _ = Nerves.UART.write(state.serial_pid, read_command)
       {sensor, state |> get_sensor_reading(sensor)}
       end)
    |> Enum.into(%{})
  end

  # Retrieves the reading for the given sensor
  defp get_sensor_reading(state, sensor) do
    case Nerves.UART.read(state.serial_pid, @read_delay_ms) do
      {:ok, value} ->
        unless is_binary(value) && String.valid?(value) do
          ""
        end

        if String.contains? value, @new_line do
          value
        else
          value <> state |> get_sensor_reading(sensor)
        end
      _ -> ""
    end
  end
end
