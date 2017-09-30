defmodule BioMonitor.RoutineProcessing do
  @moduledoc """
    The RoutineProcessing module has all the helper functions to manage the actions that need to be done on a routine.
  """
  alias BioMonitor.Routine
  alias BioMonitor.Reading
  alias BioMonitor.Repo
  alias BioMonitor.SensorManager
  alias BioMonitor.RoutineMessageBroker, as: Broker

  @ph_oscillation_tolerance 50
  @uknown_sensor_error "Ha ocurrido un error inesperado al obtener el estado de los sensores, por favor, revise las conexiones con la placa."
  @ph_out_of_range_message "El valor de ph está por fuera del rango establecido. "
  @temp_too_high_message "La temperatura está por encima del rango establecido."
  @temp_too_low_message "La temperatura está por debajo del rango establecido."

  def get_sensors_status do
    case SensorManager.get_readings()  do
      {:ok, data} ->
        Broker.send_status(data)
      {:error, message} ->
        Broker.send_sensor_error(message)
      _ ->
        Broker.send_sensor_error(@uknown_sensor_error)
    end
  end

  def fetch_reading(routine_id) do
    with {:ok, data} <- SensorManager.get_readings() do
      with routine = Repo.get(Routine, routine_id),
        true <- routine != nil,
        reading <- Ecto.build_assoc(routine, :readings),
        changeset <- Reading.changeset(reading, data),
        {:ok, reading} <- Repo.insert(changeset)
      do
        {:ok, reading}
      else
        {:error, changeset} -> {:error, changeset}
      end
    else
      {:error, message} -> register_error(message)
      _ -> register_error("Error inesperado al recolectar lecturas.")
    end
  end

  def is_offset_stable?(ph_cal) do
    case Enum.count(ph_cal.values) >= 10 do
      true ->
        case Math.Enum.mean(ph_cal.values) do
          nil -> false
          mean ->
            oscillation = Kernel.abs(mean - List.last(ph_cal.values))
            oscillation <= @ph_oscillation_tolerance
        end
      false ->
        false
    end
  end

  def send_ph_offset(target, offset) do
    case target do
      7 -> SensorManager.set_ph_offset("neutral", 7, offset)
      4 -> SensorManager.set_ph_offset("acid", 4, offset)
      10 -> SensorManager.set_ph_offset("base", 10, offset)
    end
  end

  def add_value_to_ph_cal(new_value, ph_cal) do
    case Enum.count(ph_cal.values) >= 10 do
      true ->
        %{
          ph_cal | values: ph_cal.values
            |> List.delete_at(0)
            |> List.insert_at(-1, new_value)
        }
      false ->
        %{ph_cal| values: ph_cal.values |> List.insert_at(-1, new_value)}
    end
  end

  def save_routine_sart_timestamp(routine) do
    changeset = routine
    |> Routine.started_changeset(%{started: true, started_date: DateTime.utc_now})
    case Repo.update(changeset) do
      {:ok, struct} ->
        {:ok, struct}
      {:error, _changeset} ->
        :changeset_error
    end
  end

  def process_reading(:ok, _routine) do
    IO.puts("No reading detected.")
  end

  def process_reading({:ok, reading}, routine) do
    if Kernel.abs(reading.ph - routine.target_ph) > routine.ph_tolerance do
      Broker.send_routine_error(@ph_out_of_range_message)
    end
    if reading.temp - routine.target_temp < -routine.temp_tolerance do
      Broker.send_routine_error(@temp_too_low_message)
    end
    if reading.temp - routine.target_temp > routine.temp_tolerance do
      Broker.send_routine_error(@temp_too_high_message)
    end
    Broker.send_reading(reading, routine)
  end

  def process_reading({:error, changeset}, _routine) do
    Broker.send_reading_changeset_error(changeset)
  end

  def check_for_triggers(_routine, start_timestamp) do
    IO.puts "Routine started #{System.system_time(:second) - start_timestamp} seconds ago."
    # Put any trigger processing here (such as opening a pump.)
  end

  def register_error(message) do
    # Broadcast errors.
    Broker.send_reading_error(message)
  end
end
