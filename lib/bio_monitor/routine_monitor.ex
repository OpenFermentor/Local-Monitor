defmodule BioMonitor.RoutineMonitor do
  use GenServer, otp_app: :bio_monitor

  @moduledoc """
    The RoutineMonitor is in charge of controlling the currently running routine.
  """

  @name RoutineMonitor
  # TODO change both intervals to higher values
  @reading_interval 2_000
  @loop_interval 2_000
  @ph_cal_interval 500
  @ph_oscillation_tolerance 100
  @uknown_sensor_error "Ha ocurrido un error inesperado al obtener el estado de los sensores, por favor, revise las conexiones con la placa."

  defmodule MonitorState do
    @moduledoc """
      Struct represetation of the RoutineMonitor's state.
    """
    defstruct loop: :loop, routine: %{}, ph_cal: %{target: 7, values: [], status: :not_started}
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
      :ph_cal ->
        {:reply, :ph_cal_in_progress, state}
      :loop ->
        case SensorManager.start_sensors() do
          {:ok, _message} ->
            Broker.send_start(routine)
            schedule_work(:routine_loop, @reading_interval)
            {:reply, :ok, %{state | loop: :routine, routine: routine}}
          {:error, message} ->
            Broker.send_reading_error(message)
            {:reply, {:error, "Failed to start the sensors", message}, state}
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
      :loop ->
        {:reply, :ok, %{state | loop: :ph_cal, ph_cal: %{target: target, values: [], status: :started}}}
      :routine ->
        {:reply, :routine_in_progress, state}
      :ph_cal ->
        {:reply, :ph_cal_in_progress, state}
    end
  end

  def handle_call(:ph_cal_status, _from, state) do
    {:reply, %{status: state.ph_cal.status, target: state.ph_cal.target}, state}
  end

  def handle_call(:is_running, _from, state) do
    {:reply, {:ok, state.loop == :loop}, state}
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
    end
    schedule_work(:loop, @loop_interval)
    {:noreply, state}
  end

  #Loop in charge of fetching the readings when the routine is running
  def handle_info(:routine_loop, state) do
    case state.loop do
      :routine ->
        state.routine.id
        |> fetch_reading
        |> process_reading(state.routine)
        schedule_work(:routine_loop, @reading_interval)
    end
    {:noreply, state}
  end

  #Loop in charge of running the ph calibration.
  def handle_info(:ph_cal_loop, state) do
    case state.loop do
      :ph_cal ->
        case is_offset_stable?(state.ph_cal) do
          true ->
            result = send_ph_offset(state.ph_cal.target, Math.Enum.mean(state.ph_cal.values))
            {:noreply, %{state | ph_cal: %{target: state.ph_cal.target, values: [], status: result}}}
          false ->
            case SensorManager.get_ph_offset() do
              :error -> {:noreply, %{state | ph_cal: %{target: state.ph_cal.target, values: [], status: :error}}}
              value ->
                ph_cal_upd = value |> add_value_to_ph_cal(state.ph_cal)
                schedule_work(:ph_cal_loop, @ph_cal_interval)
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
            oscillation = mean - List.last(ph_cal.values)
            oscillation <= @ph_oscillation_tolerance && oscillation >= -@ph_oscillation_tolerance
        end
      false ->
        false
    end
  end

  defp send_ph_offset(target, offset) do
    case target do
      7 -> SensorManager.set_ph_offet("neutral", offset)
      4 -> SensorManager.set_ph_offset("acid", offset)
      10 -> SensorManager.set_ph_offset("base", offset)
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

  defp process_reading(:ok, _routine) do
    IO.puts("No reading detected.")
  end

  defp process_reading({:ok, reading}, routine) do
    Broker.send_reading(reading, routine)
  end

  defp process_reading({:error, changeset}, _routine) do
    Broker.send_reading_changeset_error(changeset)
  end

  defp register_error(message) do
    # Broadcast errors.
    Broker.send_reading_error(message)
  end
end
