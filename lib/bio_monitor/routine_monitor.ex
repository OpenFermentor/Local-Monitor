defmodule BioMonitor.RoutineMonitor do
  use GenServer, otp_app: :bio_monitor

  @moduledoc """
    The RoutineMonitor is in charge of controlling the currently running routine.
  """
  alias BioMonitor.Routine
  alias BioMonitor.StateContainer

  @name RoutineMonitor
  # TODO change both intervals to higher values
  @loop_interval 2_000
  @ph_cal_interval 90_000
  @ph_balance_delay 60_000
  @ph_balance_error "Ha ocurrido un error al intentar corregir el ph, por favor revise la conexión de las bombas."
  @uknown_sensor_error "Ha ocurrido un error inesperado al obtener el estado de los sensores, por favor, revise las conexiones con la placa."

  defmodule MonitorState do
    @moduledoc """
      Struct represetation of the RoutineMonitor's state.
    """
    defstruct loop: :loop, routine: %{}, ph_cal: %{target: 7, status: :not_started}, started: 0, balancing_ph: false, target_temp: 0, triggered_pump: false
  end

  alias BioMonitor.SensorManager
  alias BioMonitor.RoutineMessageBroker, as: Broker
  alias BioMonitor.RoutineProcessing, as: Helpers

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

  def balance_ph_to_acid() do
    GenServer.cast(@name, {:balance_ph, :to_acid})
  end

  def balance_ph_to_base() do
    GenServer.cast(@name, {:balance_ph, :to_base})
  end

  # GenServer Callbacks
  def init(:ok) do
    with retry_count = StateContainer.retry_count(),
      true <- retry_count < 3,
      state <- StateContainer.state(),
      true <- state != nil
    do
      Process.sleep(10_000)
      StateContainer.update_retry_count(retry_count + 1)
      finish_init()
      {:ok, state}
    else
      _ ->
        StateContainer.reset()
        finish_init()
        {:ok, %MonitorState{}}
    end
  end

  def handle_call({:start,  routine}, _from, state) do
    case state.loop do
      :routine ->
        {:reply, :routine_in_progress, state}
      _ ->
        with {:ok, _message } <- SensorManager.start_sensors(),
          {:ok, struct} <- Helpers.save_routine_sart_timestamp(routine)
        do
          StateContainer.reset()
          Broker.send_start(routine)
          schedule_work(:routine, 1000)
          started_at =  System.system_time(:second)
          current_temp = Helpers.get_current_temp_target(struct, started_at)
          {:reply, :ok, %{state | loop: :routine, routine: struct, started: started_at, target_temp: current_temp}}
        else
          :changeset_error ->
            {:reply, {:error, "Error al guardar en la BD", "Error al actualizar el experimento"}, state}
          {:error, message} ->
            Broker.send_reading_error(message)
            Routine.log_entry(routine, Routine.log_types.reading_error, message)
            {:reply, {:error, "Error al conectar con los sensores", message}, state}
        end
    end
  end

  def handle_call(:stop, _from, state) do
    Broker.send_stop(state.routine)
    StateContainer.update_state(nil)
    {:reply, {:ok, state.routine}, %{state | loop: :loop, routine: %{}}}
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
        {:reply, :ok, %{state | loop: :ph_cal, ph_cal: %{target: target, status: :started}}}
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
        Routine.log_entry(state.routine, Routine.log_types.system_error, @uknown_sensor_error)
        Broker.send_sensor_error(@uknown_sensor_error)
    end
    {:reply, :ok, state}
  end

  def handle_cast({:balance_ph, :to_acid}, state) do
    IO.puts "~~~~~~~~~~~~~~~~~~~~~"
    IO.puts "Balancing PH to acid"
    IO.puts "~~~~~~~~~~~~~~~~~~~~~"
    case SensorManager.pump_acid() do
      :ok ->
        Routine.log_entry(state.routine, Routine.log_types.acid_cal,
        "Bomba de ácido activada")
        {:noreply, %{state | balancing_ph: true}}
      {:error, _message} ->
        Routine.log_entry(state.routine, Routine.log_types.system_error, @ph_balance_error)
        Broker.send_system_error(@ph_balance_error)
        {:noreply, %{state | balancing_ph: false}}
    end
  end

  def handle_cast({:balance_ph, :to_base}, state) do
    IO.puts "====================="
    IO.puts "Balancing PH to base"
    IO.puts "====================="
    case SensorManager.pump_base() do
      :ok ->
        Routine.log_entry(state.routine, Routine.log_types.base_cal, "Bomba de base activada")
        {:noreply, %{state | balancing_ph: true}}
      {:error, _message} ->
        Routine.log_entry(state.routine, Routine.log_types.system_error, @ph_balance_error)
        Broker.send_system_error(@ph_balance_error)
        {:noreply, %{state | balancing_ph: false}}
    end
  end

  #Loop in charge of checking the status of the sensors when the routine is not running
  def handle_info(:loop, state) do
    case state.loop do
      :loop ->
        Helpers.get_sensors_status()
        schedule_work(:loop, @loop_interval)
        {:noreply, state}
      :routine ->
        if !state.balancing_ph && !state.triggered_pump do
          pumped = Helpers.check_for_pump_trigger(state.routine, state.started)
          schedule_work(:loop, @loop_interval)
          {:noreply, %{state | triggered_pump: pumped}}
        else
          schedule_work(:loop, @loop_interval)
          {:noreply, state}
        end
      _ ->
        schedule_work(:loop, @loop_interval)
        {:noreply, state}
    end
  end

  #Loop in charge of fetching the readings when the routine is running
  def handle_info(:routine, state) do
    case state.loop do
      :routine ->
        case state.balancing_ph do
          true ->
            reading = state.routine.id
            |> Helpers.fetch_reading
            |> Helpers.process_reading(state.routine, state.target_temp)
            schedule_work(:routine, @ph_balance_delay)
            balancing_ph = Kernel.abs(reading.ph - state.routine.target_ph) > state.routine.ph_tolerance && state.routine.balance_ph
            {:noreply, %{state | balancing_ph: balancing_ph}}
          false ->
            new_temp = Helpers.get_current_temp_target(state.routine, state.started)
            if new_temp != state.target_temp do
              Routine.log_entry(state.routine, Routine.log_types.temp_change, "Cambió la temperatura objetivo a #{new_temp} grados.")
              Broker.send_instruction("Por favor, colocar el circulador a #{new_temp} grados.")
            end
            state = %{state | target_temp: new_temp}
            reading = state.routine.id
            |> Helpers.fetch_reading
            |> Helpers.process_reading(state.routine, state.target_temp)
            Helpers.check_for_triggers(state.routine, state.started)
            case reading do
              {:ok, reading} ->
                balancing_ph = Kernel.abs(reading.ph - state.routine.target_ph) > state.routine.ph_tolerance && state.routine.balance_ph
                delay = if balancing_ph, do: @ph_balance_delay, else: state.routine.loop_delay
                schedule_work(:routine, delay)
              _ -> schedule_work(:routine, state.routine.loop_delay)
            end
            {:noreply, state}
        end
        _ -> {:noreply, state}
    end
  end

  def handle_info(:ph_cal, state) do
    case state.loop do
      :ph_cal ->
        result = Helpers.calibrate_ph_for_target(state.ph_cal.target)
        {:noreply, %{state | loop: :loop, ph_cal: %{target: state.ph_cal.target, status: result}}}
      _ -> {:noreply, state}
    end
  end


  def handle_info(_, state) do
    IO.puts("Uknown message received.")
    {:noreply, state}
  end

  def terminate(reason, state) do
    case reason do
      :normal ->
        IO.puts "Server terminated normally"
      _ ->
        if StateContainer.retry_count < 3 do
          StateContainer.update_state(state)
        else
          StateContainer.update_state(nil)
          Broker.send_system_error(
            "Ocurrió un error inesperado en el sistema y el experimento se ha detenido, por favor revise las conexiones con la placa y reinicie el experimento."
          )
        end
    end
  end

  # Helpers
  defp finish_init() do
    case SensorManager.start_sensors() do
      {:ok, _message} ->
        schedule_work(:loop, @loop_interval)
      {:error, _message} ->
        Broker.send_sensor_error(@uknown_sensor_error)
    end
  end

  defp schedule_work(loop_name, delay) do
    Process.send_after(self(), loop_name, delay)
  end
end
