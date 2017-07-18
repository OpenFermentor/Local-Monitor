defmodule BioMonitor.RoutineMonitor do
  use GenServer, otp_app: :bio_monitor

  @moduledoc """
    The RoutineMonitor is in charge of controlling the currently running routine.
  """

  @name RoutineMonitor
  @reading_interval 5_000
  @channel "routine"
  @started_msg "started"
  @stopped_msg "stopped"
  @update_msg "update"
  @alert_msg "alert"
  @sensors_channel "sensors"
  @status_msg "status"
  @error_msg "error"
  @uknown_sensor_error "Uknown error while getting sensor status, please check the boards connections"

  alias BioMonitor.Endpoint
  alias BioMonitor.Routine
  alias BioMonitor.Reading
  alias BioMonitor.Repo
  alias BioMonitor.SensorManager
  alias BioMonitor.SyncServer

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

  def is_running?()do
    GenServer.call(@name, :is_running)
  end

  # GenServer Callbacks
  def init(:ok) do
    case SensorManager.start_sensors() do
      {:ok, _message} ->
        schedule_work()
      {:error, _message} ->
        Endpoint.broadcast(
          @sensors_channel,
          @error_msg,
          %{message: @uknown_sensor_error}
        )
        SyncServer.send(@error_msg, @uknown_sensor_error)
    end
    {:ok, %{:loop => false, :routine => %{}}}
  end

  def handle_call({:start,  routine}, _from, state = %{loop: runLoop, routine: _routine}) do
    case runLoop do
      true ->
        {:reply, :routine_in_progress, state}
      false ->
        case SensorManager.start_sensors() do
          {:ok, _message} ->
            Endpoint.broadcast(
              @channel,
              @started_msg,
              %{message: "Started routine", routine: routine_to_map(routine)}
            )
            SyncServer.send(@started_msg, routine_to_map(routine))
            schedule_work()
            {:reply, :ok, %{:loop => true, :routine => routine}}
          {:error, message} ->
            {:reply, {:error, "Failed to start the sensors", message}, state}
        end
    end
  end

  def handle_call(:stop, _from, %{loop: _runLoop, routine: routine}) do
    Endpoint.broadcast(
      @channel,
      @stopped_msg,
      %{message: "Stopped routine", routine: routine_to_map(routine)}
    )
    {:reply, :ok, %{loop: false, routine: %{}}}
  end

  def handle_call({:update, routine}, _from, _state) do
    {:reply, :ok, %{:loop => true, :routine => routine}}
  end

  def handle_call(:is_running, _from, state = %{loop: runLoop, routine: _routine}) do
    {:reply, {:ok, runLoop}, state}
  end

  def handle_info(:loop, state = %{loop: runLoop, routine: routine}) do
    case runLoop do
      true ->
        routine.id
        |> fetch_reading
        |> process_reading(routine)
        schedule_work()
      false ->
        get_sensors_status()
        schedule_work()
    end
    {:noreply, state}
  end

  def terminate(reason, _state) do
    case reason do
      :normal ->
        IO.puts 'Server terminated normally'
      :shutdown ->
        IO.puts 'Server shutted down'
      _ ->
        IO.puts 'Uknown error'
    end
  end

  # Helpers
  defp schedule_work do
    Process.send_after(self(), :loop, @reading_interval)
  end

  defp get_sensors_status do
    case SensorManager.get_readings()  do
      {:ok, data} ->
        Endpoint.broadcast(
          @sensors_channel,
          @status_msg,
          data
        )
        SyncServer.send(@status_msg, data)
      {:error, message} ->
        Endpoint.broadcast(
          @sensors_channel,
          @error_msg,
          %{message: message}
        )
        SyncServer.send(@error_msg, %{message: message})
      _ ->
        Endpoint.broadcast(
          @sensors_channel,
          @error_msg,
          %{message: @uknown_sensor_error}
        )
        SyncServer.send(@error_msg, %{message: @uknown_sensor_error})
    end
  end

  defp fetch_reading(routine_id) do
    IO.puts 'Fetching reading from sensors.'
    with {:ok, data} <- SensorManager.get_readings() do
      with routine = Repo.get(Routine, routine_id),
        true <- routine != nil,
        reading <- Ecto.build_assoc(routine, :readings),
        changeset <- Reading.changeset(reading, data),
        {:ok, reading} <- Repo.insert(changeset)
      do
        IO.puts("Successfuly saved new reading.")
        {:ok, reading}
      else
        {:error, changeset} -> {:error, changeset}
      end
    else
      {:error, message} -> register_error(message)
      _ -> register_error("Unexpected error")
    end
  end

  defp process_reading(:ok, _routine) do
    IO.puts("No reading detected.")
  end

  defp process_reading({:ok, reading}, routine) do
    IO.puts(
      "Processing new reading for routine #{routine.id} temperature is: #{reading.temp}"
    )
    Endpoint.broadcast(@channel, @update_msg, reading_to_map(reading, routine))
    SyncServer.send(@update_msg, reading_to_map(reading, routine))
  end

  defp process_reading({:error, changeset}, routine) do
    IO.puts("Changeset error for #{routine.id}")
    Endpoint.broadcast(
      @channel,
      @alert_msg,
      %{
        message: "Error while saving the reading",
        errors: changeset.errors
      }
    )
    SyncServer.send(
      @alert_msg,
      %{
        message: "Error while saving the reading",
        errors: changeset.errors
      }
    )
  end

  defp register_error(message) do
    # Broadcast errors.
    IO.puts("An error has ocurred while fetching the reading")
    IO.puts(message)
    Endpoint.broadcast(
      @channel,
      @alert_msg,
      %{
        message: "Error while saving the reading",
        errors: [message]
      }
    )
    SyncServer.send(
      @alert_msg,
      %{
        message: "Error while saving the reading",
        errors: [message]
      }
    )
  end

  defp reading_to_map(reading, routine) do
    %{
      routine_id: routine.id,
      id: reading.id,
      temp: reading.temp,
      inserted_at: reading.inserted_at
    }
  end

  defp routine_to_map(routine) do
    %{
      id: routine.id,
      target_temp: routine.target_temp,
      inserted_at: routine.inserted_at
    }
  end
end
