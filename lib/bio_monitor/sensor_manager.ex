defmodule BioMonitor.SensorManager do
  @moduledoc """
    Wrapper module around all serial communication with
    all sensors using a SerialMonitor instance.
  """

  @doc """
    Adds all sensors specified in the config file to the
    SerialMonitor.
  """
  def start_sensors() do
    with sensor_specs = Application.get_env(:bio_monitor, BioMonitor.SensorManager),
      false <- sensor_specs == nil,
      sensor_map <- process_specs(sensor_specs)
    do
      # Call SerialMonitor and register all sensors here
      {:ok, sensor_map}
    else
      _ ->
        {:error, "Error while processing config file, please check config.exs"}
    end
  end

  @doc """
    Fetchs all readings from the SerialMonitors and parse them.
  """
  def get_readings() do
    {:ok, %{temp: 0, ph: 0, co2: 0, density: 0}}
  end

  @doc """
    Sends a command for an specific sensor.
  """
  def send_command({_sensor, _command}) do
    {:ok, "response here"}
  end


  #Procesess the keyword list returned from the config file to a
  #list of maps to send to the SerialMonitor
  defp process_specs(sensor_specs) do
    sensor_specs
    |> Enum.map(fn {_key, sensor_spec} ->
      %{
        port: sensor_spec[:port],
        sensors: sensor_spec[:sensors] |> Enum.into(%{})
      }
    end)
  end

end
