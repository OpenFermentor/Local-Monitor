defmodule BioMonitor.RoutineProcessing do
  @moduledoc """
    The RoutineProcessing module has all the helper functions to manage the actions that need to be done on a routine.
  """
  alias BioMonitor.Routine
  alias BioMonitor.Reading
  alias BioMonitor.Repo
  alias BioMonitor.SensorManager
  alias BioMonitor.RoutineMonitor
  alias BioMonitor.RoutineMessageBroker, as: Broker

  @ph_oscillation_tolerance 50
  @uknown_sensor_error "Ha ocurrido un error inesperado al obtener el estado de los sensores, por favor, revise las conexiones con la placa."
  @ph_out_of_range_message "El valor de ph está por fuera del rango establecido. "
  @temp_too_high_message "La temperatura está por encima del rango establecido."
  @temp_too_low_message "La temperatura está por debajo del rango establecido."

  def get_sensors_status do
    case SensorManager.get_sensors_status()  do
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

  def calibrate_ph_for_target(target) do
    case target do
      7 -> SensorManager.calibratePh("N")
      4 -> SensorManager.calibratePh("A")
      10 -> SensorManager.calibratePh("B")
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

  def process_reading(:ok, _routine, _temp_target) do
    IO.puts("No reading detected.")
  end

  def process_reading({:ok, reading}, routine, temp_target) do
    if Kernel.abs(reading.ph - routine.target_ph) > routine.ph_tolerance do
      Routine.log_entry(routine, Routine.log_types.reading_error, @ph_out_of_range_message)
      Broker.send_routine_error(@ph_out_of_range_message)
      if routine.balance_ph do
        start_ph_balance(reading.ph, routine.target_ph, routine.ph_tolerance)
      end
    end
    if reading.temp - temp_target < -routine.temp_tolerance do
      Broker.send_routine_error(@temp_too_low_message)
      Routine.log_entry(routine, Routine.log_types.reading_error, @temp_too_low_message)
    end
    if reading.temp - temp_target > routine.temp_tolerance do
      Routine.log_entry(routine, Routine.log_types.reading_error, @temp_too_high_message)
      Broker.send_routine_error(@temp_too_high_message)
    end
    Broker.send_reading(reading, routine)
    reading
  end

  def process_reading({:error, changeset}, _routine, _temp_target) do
    Broker.send_reading_changeset_error(changeset)
  end

  def start_ph_balance(ph, target_ph, tolerance) do
    if ph - target_ph < -tolerance do
      RoutineMonitor.balance_ph_to_base()
    end
    if ph - target_ph > tolerance do
      RoutineMonitor.balance_ph_to_acid()
    end
  end

  def check_for_triggers(_routine, start_timestamp) do
    IO.puts "Routine started #{System.system_time(:second) - start_timestamp} seconds ago."
    # Put any trigger processing here (such as opening a pump.)
  end

  def register_error(message) do
    # Broadcast errors.
    Broker.send_reading_error(message)
  end

  def check_for_pump_trigger(routine, timestamp) do
    elapsed_time = System.system_time(:second) - timestamp # Get the current second of the running routine.
    if elapsed_time >= routine.trigger_after do
      case SensorManager.pump_trigger(routine.trigger_for) do
        :ok -> true
        {:error, _message} -> false
      end
    else
      false
    end
  end

  def get_current_temp_target(routine, timestamp) do
    routine = Repo.preload(routine, [:temp_ranges, :tags])
    elapsed_time = System.system_time(:second) - timestamp # Get the current second of the running routine.
    current = routine.temp_ranges # Find the latest range (the one that should be running)
    |> Enum.filter(fn target ->
      target.from_second <= elapsed_time
    end)
    |> Enum.map(fn target -> target.from_second end)
    |> Enum.max(fn -> nil end)
    case current do
      nil ->
        IO.puts "current temp #{routine.target_temp}"
        routine.target_temp
      from_second ->
        range = routine.temp_ranges
          |> Enum.find(fn range ->
              range.from_second === from_second
            end)
        IO.puts "current temp #{range.temp}"
        range.temp
    end
  end
end
