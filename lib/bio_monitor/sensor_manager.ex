defmodule BioMonitor.SensorManager do
  @moduledoc """
    Wrapper module around all serial communication with
    all sensors using a SerialMonitor instance.
  """
  alias BioMonitor.SerialMonitor

  # Name used for the arduino board.
  @arduino_gs ArduinoGenServer

  @doc """
    Helper to expose arduino's serial monitor identifier.
  """
  def arduino_gs_id, do: @arduino_gs


  @doc """
    Adds all sensors specified in the config file to the
    SerialMonitor.
  """
  def start_sensors() do
    with sensor_specs = Application.get_env(:bio_monitor, BioMonitor.SensorManager),
      false <- sensor_specs == nil,
      arduino_spec <- process_specs(sensor_specs[:arduino]),
      :ok <- SerialMonitor.set_port(@arduino_gs, arduino_spec.port, arduino_spec.speed)
    do
      #Register sensors here.
      SerialMonitor.add_sensors(@arduino_gs, arduino_spec[:sensors])
      {:ok, "Sensor ready"}
    else
      {:error, _} ->
        {:error, "There was a problem connecting to the sensor."}
      _ ->
        {:error, "Error while processing config file, please check config.exs"}
    end
  end

  @doc """
    Fetchs all readings from the SerialMonitors and parse them.
  """
  def get_readings() do
    with {:ok, arduino_readings} <- SerialMonitor.get_readings(@arduino_gs),
      {temp, _} <- Float.parse(arduino_readings[:temp])
    do
      {:ok, %{temp: temp, ph: 0, co2: 0, density: 0}}
    else
      :error ->
        {:error, "There was an error fetching the readings"}
      _ ->
        {:error, "Unexpected error, please check the board connections"}
    end
  end

  @doc """
    Sends a command for an specific sensor.
    sensor should be one of the previously reigstered sensors.
  """
  def send_command(sensor, command) do
    with {:ok, gs_name} <- gs_name_for_sensor(sensor),
      {:ok, result} <- SerialMonitor.send_command(gs_name, command)
    do
      {:ok, result}
    else
      {:error, message} ->
        {:error, "Error sending command", message}
      :error ->
        {:error, "No sensor matches any port"}
    end
  end


  #Procesess the keyword list returned from the config file to a
  #list of maps to send to the SerialMonitor with the following format:
  # [
  # %{
  #   port: "dummy port",
  #   sensors: [temp: "getTemp", ph: "getPh"],
  #   speed: 9600
  #  }
  #]
  defp process_specs(sensor_spec) do
    %{
      port: sensor_spec[:port],
      speed: sensor_spec[:speed],
      sensors: sensor_spec[:sensors]
    }
  end

  defp gs_name_for_sensor(sensor) do
    case sensor do
      :temp -> {:ok, @arduino_gs}
      _ -> :error
    end
  end

end
