defmodule BioMonitor.RoutineMessageBroker do
  @moduledoc """
    Wrapper module around all channel
    communication for all routine related operations.
  """
  # Routine channel
  @channel "routine"
  @started_msg "started"
  @stopped_msg "stopped"
  @update_msg "update"
  @alert_msg "alert"
  # Sensor channel
  @sensors_channel "sensors"
  @status_msg "status"
  @error_msg "error"
  # "status" code for alert and error topics on routine and sensors channels
  @routine_error :reading_error
  @sensor_error :sensor_error
  @system_error :system_error
  # Instructions channel
  @instructions_channel "instructions"
  @instruction "instruction"

  alias BioMonitor.Endpoint
  alias BioMonitor.CloudSync

  def send_sensor_error(message) do
    Endpoint.broadcast(
        @sensors_channel,
        @error_msg,
        %{status: @sensor_error, message: message}
      )
    CloudSync.sensor_error(%{status: @sensor_error, message: message})
  end

  def send_system_error(message) do
    Endpoint.broadcast(
      @channel,
      @alert_msg,
      %{status: @system_error, message: message}
    )
    Endpoint.broadcast(
      @sensors_channel,
      @error_msg,
      %{status: @system_error, message: message}
    )
    CloudSync.alert(%{status: @system_error, message: message})
    CloudSync.sensor_error(%{status: @system_error, message: message})
  end

  def send_routine_error(message) do
    Endpoint.broadcast(
      @channel,
      @alert_msg,
      %{message: message}
    )
    CloudSync.alert(%{status: @routine_error, message: message})
  end

  def send_start(routine) do
    Endpoint.broadcast(
      @channel,
      @started_msg,
      %{message: "Started routine", routine: routine_to_map(routine)}
    )
    CloudSync.started_routine(routine_to_map(routine))
  end

  def send_stop(routine) do
    Endpoint.broadcast(
      @channel,
      @stopped_msg,
      %{message: "Experimento finalizado", routine: routine_to_map(routine)}
    )
    CloudSync.stopped_routine(routine_to_map(routine))
  end

  def send_status(status) do
    Endpoint.broadcast(
      @sensors_channel,
      @status_msg,
      status
    )
    CloudSync.sensor_status(status)
  end

  def send_reading(reading, routine) do
    Endpoint.broadcast(@channel, @update_msg, reading_to_map(reading, routine))
    CloudSync.new_reading(reading_to_map(reading, routine))
  end

  def send_reading_changeset_error(changeset) do
    Endpoint.broadcast(
      @channel,
      @alert_msg,
      %{
        status: @routine_error,
        message: "Hubo un error al guardar una lectura.",
        errors: changeset.errors
      }
    )
    CloudSync.alert(
      %{
        status: @routine_error,
        message: "Hubo un error al guardar una lectura.",
        errors: changeset.errors
      }
    )
  end

  def send_reading_error(message) do
    Endpoint.broadcast(
      @channel,
      @alert_msg,
      %{
        status: @routine_error,
        message: "Hubo un error al guardar una lectura.",
        errors: [message]
      }
    )
    CloudSync.alert(
      %{
        status: @routine_error,
        message: "Hubo un error al guardar una lectura.",
        errors: [message]
      }
    )
  end

  def send_instruction(message) do
    Endpoint.broadcast(
      @instructions_channel,
      @instruction,
      %{
        message: message,
      }
    )
    CloudSync.instruction(%{
      message: message,
    })
  end

  defp reading_to_map(reading, routine) do
    %{
      routine_id: routine.id,
      routine_uuid: routine.uuid,
      id: reading.id,
      temp: reading.temp,
      ph: reading.ph,
      product: reading.product,
      biomass: reading.biomass,
      substratum: reading.substratum,
      inserted_at: reading.inserted_at
    }
  end

  defp routine_to_map(routine) do
    %{
      id: routine.id,
      uuid: routine.uuid,
      target_temp: routine.target_temp,
      inserted_at: routine.inserted_at
    }
  end
end
