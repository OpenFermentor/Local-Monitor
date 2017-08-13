defmodule BioMonitor.SerialMonitor do
  use GenServer

  @moduledoc """
    The SerialMonitor is in charge of the serial communication with the sensors
  """

  alias Nerves.UART

  @read_delay_ms 2_000
  @new_line "\n"
  @end_reading "\r\n"

  @wrong_argunment "Wrong argument"
  @unrecognized_command "Unrecognized Command"
  @generic_error "ERROR"

  @error_sending_command "The command could not be sent"
  @error_connection_reading "There was a connection error while reading data from sensor"

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Returns a list of available ports and the devices connected to them

  pid: The PID of the running process
  """
  def get_ports(pid) do
    GenServer.call(pid, :get_ports)
  end

  @doc """
  Sets the port where the device is connected

  pid: The PID of the running process
  name: The name identifier of the port (use `get_ports/0` to retrieve it)
  speed: The speed of the serial port
  """
  def set_port(pid, name, speed) do
    GenServer.call(pid, {:set_port, %{name: name, speed: speed}})
  end

  @doc """
  Adds the sensors whose information comes through the connected device

  pid: The PID of the running process
  sensors: Key value pair, where the key is an atom representing the type of
           the sensor, and the value is the command to fetch the data

  ## Examples

  add_sensor [temp: "getTemp", ph: "getPh"]
  """
  def add_sensors(pid, sensors) do
    GenServer.call(pid, {:add_sensors, %{sensors: sensors}})
  end

  @doc """
  Retrieves the readings for the registered sensors

  pid: The PID of the running process

  ## Examples
  If :temp and :ph sensors are defined, then the returned value would be:

  {:ok, [temp: "20.75", ph: {:error, "Unrecognized Command"}]}
  """
  def get_readings(pid) do
    GenServer.call(pid, :get_readings)
  end

  @doc """
  Sends a command to the sensor.

  pid: The PID of the running process

  command: The String instruction to be sent to the sensor
  """
  def send_command(pid, command) do
    GenServer.call(pid, {:send_command, %{command: command}})
  end

  def clean_serial(pid) do
    GenServer.call(pid, :clean_serial)
  end

  @doc """
  State structure:
  %{
    serial_pid: The pid of the process that handles serial connectivity
    port: The port information to establish a connection with the device
    sensors: Key value pair, where the key is an atom representing the type of
             the sensor, and the value is the command to fetch the data
  }

  ## Examples

  %{
    serial_pid: 1234,
    port: %{
      name: The name of the serial port where the device is connected
      speed: The speed of the serial port
    }
    sensors: [
      %{temp => "getTemp"},
      %{ph => "getPh"}
    ]
  }
  """
  def init(:ok) do
    {:ok, pid} = UART.start_link
    {:ok, %{serial_pid: pid, port: %{}, sensors: []}}
  end

  @doc """
  Lists the available ports in the device with the connected devices information,
  such as manufacter id, etc.
  """
  def handle_call(:get_ports, _from, state) do
    {:reply, {:ok, UART.enumerate}, state}
  end

  @doc """
  Sets the port where the device is connected

  name: The name identifier of the port (use `get_ports/3` to retrieve it)
  speed: The speed of the serial port
  """
  def handle_call({:set_port, %{name: name, speed: speed}}, _from, state) do
    case result = open_connection state.serial_pid, name, speed do
      :ok ->
        clean_serial_port(state.serial_pid)
        {:reply, result, %{state | port: %{name: name, speed: speed}}}
      _ ->
        {:reply, result, %{state | port: %{name: name, speed: speed}}}
    end
  end

  @doc """
  Register the sensors to read and execute commands.
  Data format: %{
    sensors: Key value pair, where the key is an atom representing the type of
             the sensor, and the value is the command to fetch the data
  }

  ## Examples

  [
    %{temp => "getTemp"},
    %{ph => "getPh"}
  ]
  """
  def handle_call({:add_sensors, %{sensors: sensors}}, _from, state) do
    {:reply, :ok, %{state | sensors: sensors}}
  end

  @doc """
  Retrieves a hash of key value pairs containing the readings for each of the
  registered sensors.

  ## Example

  [
    %{temp => 28.0}
    %{ph => 7.1}
  ]
  """
  def handle_call(:get_readings, _from, state) do
    {:reply, {:ok, state |> get_sensor_readings}, state}
  end

  @doc """
  Sends the `command` to to the device
  """
  def handle_call({:send_command, %{command: command}}, _from, state) do
    result = UART.write(state.serial_pid, command)
    {
      :reply,
      (if result == :ok, do: result, else: {:error, @error_sending_command}),
      state
    }
  end

  def handle_call(:clean_serial, _from, state) do
    clean_serial_port(state.serial_pid)
    {:reply, :ok, state}
  end

  # Opens the connection to the device in the given port
  #
  # uart_pid: The PID of the Nerves process
  # port: The port where the device is located
  # speed: The speed of the serial port
  defp open_connection(uart_pid, port, speed) do
    UART.open(uart_pid, port, speed: speed, active: false)
  end

  # Returns the readings for the registered sensors
  #
  # state: The state of the application
  #
  # Example
  #
  # [
  #   %{temp => "28.0"}
  #   %{ph => "7.1"}
  # ]
  defp get_sensor_readings(state) do
    state.sensors
      |> Enum.map(fn {sensor, read_command} ->
          _ = UART.write(state.serial_pid, read_command)
          {sensor, state |> get_sensor_reading |> parse_reading}
         end)
  end

  # Retrieves the reading for the given sensor
  #
  # state: The state of the application
  #
  # Example:
  #
  # "28.0"
  # or
  # :error
  defp get_sensor_reading(state) do
    case UART.read(state.serial_pid, @read_delay_ms) do
      {:ok, value} ->
        unless is_binary(value) && String.valid?(value) do
          :error
        end

        if String.contains? value, @new_line do
          value
        else
          result = state |> get_sensor_reading
          if result == :error, do: :error, else: value <> result
        end
      _ ->
        :error
    end
  end

  # Parses the seansor reading to sanitize and account for errors
  #
  # reading: The String reading to parse
  #
  # Example:
  #
  # "28.0"
  # or
  # {:error, "Some error"}
  defp parse_reading(reading) do
    case reading do
      :error ->
        {:error, @error_connection_reading}
      value ->
        value = value |> String.trim_trailing(@end_reading)
        if value |> is_reading_error, do: {:error, value}, else: value
    end
  end

  # Recognizes if the reading is any of the known error messages
  defp is_reading_error(reading) do
    errors = [@unrecognized_command, @wrong_argunment, @generic_error]
    Enum.any?(errors, fn(e) -> String.contains? reading, e end)
  end

  defp clean_serial_port(pid) do
    case UART.read(pid, @read_delay_ms) do
      {:ok, ""} -> :ok
      {:ok, _value} ->
        clean_serial_port(pid)
      {:error, _} -> :ok
    end
  end
end
