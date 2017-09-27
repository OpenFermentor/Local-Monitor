defmodule BioMonitor.RoutineMonitor do
  use GenServer, otp_app: :bio_monitor

  @moduledoc """
    The RoutineMonitor is in charge of controlling the currently running routine.
  """

  @name RoutineMonitor
  # TODO change both intervals to higher values
  @loop_interval 2_000
  @ph_cal_interval 1_000
  @ph_oscillation_tolerance 50
  @uknown_sensor_error "Ha ocurrido un error inesperado al obtener el estado de los sensores, por favor, revise las conexiones con la placa."
  @ph_out_of_range_message "El valor de ph está por fuera del rango establecido. "
  @temp_too_high_message "La temperatura está por encima del rango establecido."
  @temp_too_low_message "La temperatura está por debajo del rango establecido."

  defmodule MonitorState do
    @moduledoc """
      Struct represetation of the RoutineMonitor's state.
    """
    defstruct loop: :loop, routine: %{}, ph_cal: %{target: 7, values: [], status: :not_started}, started: 0
  end

  alias BioMonitor.Routine
  alias BioMonitor.Reading
  alias BioMonitor.Repo
  alias BioMonitor.SensorManager
  alias BioMonitor.RoutineMessageBroker, as: Broker

  # User API
  def start_link do
    start_server()
  end

  def start_server do
    GenServer.start_link(__MODULE__, :ok, [name: @name])
  end

  def start_routine(routine) do
    GenServer.call(@name, {:start, routine})
  end

  def stop_routine do
    GenServer.call(@name, :stop)
  end

  def update_routine(routine) do
    GenServer.call(@name, {:update, routine})
  end

  def start_ph_cal(target) do
    GenServer.call(@name, {:start_ph_cal, target})
  end

  def ph_cal_status() do
    GenServer.call(@name, :ph_cal_status)
  end

  def is_running?()do
    GenServer.call(@name, :is_running)
  end

  def current_routine() do
    GenServer.call(@name, :current_routine)
  end

  def start_loop() do
    GenServer.call(@name, :start_loop)
  end

  # GenServer Callbacks
  def init(:ok) do
    case SensorManager.start_sensors() do
      {:ok, _message} ->
        schedule_work(:loop, @loop_interval)
      {:error, _message} ->
        Broker.send_sensor_error(@uknown_sensor_error)
    end
    {:ok, %MonitorState{}}
  end

  def handle_call({:start,  routine}, _from, state) do
    case state.loop do
      :routine ->
        {:reply, :routine_in_progress, state}
      _ ->
        with {:ok, _message } <- SensorManager.start_sensors(),
          {:ok, _struct} <- save_routine_sart_timestamp(routine)
        do
          Broker.send_start(routine)
          schedule_work(:routine, routine.loop_delay)
          {:reply, :ok, %{state | loop: :routine, routine: routine, started: System.system_time(:second)}}
        else
          :changeset_error ->
            {:reply, {:error, "Error al guardar en la BD", "Error al actualizar el experimento"}, state}
          {:error, message} ->
            Broker.send_reading_error(message)
            {:reply, {:error, "Error al conectar con los sensores", message}, state}
        end
    end
  end

  def handle_call(:stop, _from, state) do
    Broker.send_stop(state.routine)
    {:reply, :ok, %{state | loop: :loop, routine: %{}}}
  end

  def handle_call({:update, routine}, _from, state) do
    {:reply, :ok, %{state | loop: :routine, routine: routine}}
  end

  def handle_call({:start_ph_cal, target}, _from, state) do
    case state.loop do
      :routine ->
        {:reply, :routine_in_progress, state}
      _ ->
        schedule_work(:ph_cal, @ph_cal_interval)
        {:reply, :ok, %{state | loop: :ph_cal, ph_cal: %{target: target, values: [], status: :started}}}
    end
  end

  def handle_call(:ph_cal_status, _from, state) do
    {:reply, %{status: state.ph_cal.status, target: state.ph_cal.target}, state}
  end

  def handle_call(:is_running, _from, state) do
    {:reply, {:ok, state.loop == :routine}, state}
  end

  def handle_call(:current_routine, _from, state) do
    case state.loop do
      :routine -> {:reply, {:ok, state.routine}, state}
      _ -> {:reply, :not_running, state}
    end

  end

  def handle_call(:start_loop, _from, state) do
    case SensorManager.start_sensors() do
      {:ok, _message} ->
        schedule_work(:loop, @loop_interval)
      {:error, _message} ->
        Broker.send_sensor_error(@uknown_sensor_error)
    end
    {:reply, :ok, state}
  end

  #Loop in charge of checking the status of the sensors when the routine is not running
  def handle_info(:loop, state) do
    case state.loop do
      :loop ->
        get_sensors_status()
      _ -> nil
    end
    schedule_work(:loop, @loop_interval)
    {:noreply, state}
  end

  #Loop in charge of fetching the readings when the routine is running
  def handle_info(:routine, state) do
    case state.loop do
      :routine ->
        state.routine.id
        |> fetch_reading
        |> process_reading(state.routine)
        check_for_triggers(state.routine, state.started)
        schedule_work(:routine, state.routine.loop_delay)
      _ -> nil
    end
    {:noreply, state}
  end

  #Loop in charge of running the ph calibration.
  def handle_info(:ph_cal, state) do
    case state.loop do
      :ph_cal ->
        case is_offset_stable?(state.ph_cal) do
          true ->
            result = send_ph_offset(state.ph_cal.target, Math.Enum.mean(state.ph_cal.values))
            {:noreply, %{state | loop: :loop, ph_cal: %{target: state.ph_cal.target, values: [], status: result}}}
          false ->
            case SensorManager.get_ph_offset() do
              :error -> {:noreply, %{state | loop: :loop, ph_cal: %{target: state.ph_cal.target, values: [], status: :error}}}
              value ->
                ph_cal_upd = value |> add_value_to_ph_cal(state.ph_cal)
                schedule_work(:ph_cal, @ph_cal_interval)
                {:noreply, %{state | ph_cal: ph_cal_upd}}
            end
        end
      _ ->
        {:noreply, state}
    end
  end

  def handle_info(_, _state) do
    IO.puts("Uknown message received.")
  end

  def terminate(reason, _state) do
    case reason do
      :normal ->
        IO.puts "Server terminated normally"
      _ ->
        Broker.send_system_error(
          "Ocurrió un error inesperado en el sistema y el experimento se ha detenido, por favor revise las conexiones con la placa y reinicie el experimento."
        )
    end
  end

  # Helpers
  defp schedule_work(loop_name, delay) do
    Process.send_after(self(), loop_name, delay)
  end

  defp get_sensors_status do
    case SensorManager.get_readings()  do
      {:ok, data} ->
        Broker.send_status(data)
      {:error, message} ->
        Broker.send_sensor_error(message)
      _ ->
        Broker.send_sensor_error(@uknown_sensor_error)
    end
  end

  defp fetch_reading(routine_id) do
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

  defp is_offset_stable?(ph_cal) do
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

  defp send_ph_offset(target, offset) do
    case target do
      7 -> SensorManager.set_ph_offset("neutral", 7, offset)
      4 -> SensorManager.set_ph_offset("acid", 4, offset)
      10 -> SensorManager.set_ph_offset("base", 10, offset)
    end
  end

  defp add_value_to_ph_cal(new_value, ph_cal) do
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

  defp save_routine_sart_timestamp(routine) do
    changeset = routine
    |> Routine.started_changeset(%{started: true, started_date: DateTime.utc_now})
    case Repo.update(changeset) do
      {:ok, struct} ->
        {:ok, struct}
      {:error, _changeset} ->
        :changeset_error
    end
  end

  defp process_reading(:ok, _routine) do
    IO.puts("No reading detected.")
  end

  defp process_reading({:ok, reading}, routine) do
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

  defp process_reading({:error, changeset}, _routine) do
    Broker.send_reading_changeset_error(changeset)
  end

  defp check_for_triggers(_routine, start_timestamp) do
    IO.puts "Routine started #{System.system_time(:second) - start_timestamp} seconds ago."
    # Put any trigger processing here (such as opening a pump.)
  end

  defp register_error(message) do
    # Broadcast errors.
    Broker.send_reading_error(message)
  end
end
